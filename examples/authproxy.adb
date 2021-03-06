--
-- \brief  JWT authentication proxy demo
-- \author Alexander Senier
-- \date   2018-06-24
--
-- Copyright (C) 2018 Componolit GmbH
--
-- This file is part of JWX, which is distributed under the terms of the
-- GNU Affero General Public License version 3.
--

with GNAT.Sockets; use GNAT.Sockets;
with GNAT.Command_Line; use GNAT.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;

with JWX.Stream_Auth;
with JWX_Test_Utils; use JWX_Test_Utils;

procedure Authproxy
is
   Server_Socket  : Socket_Type;

   Client_Socket  : Socket_Type;
   Client_Address : Sock_Addr_Type;

   Audience : constant String := "4cCy0QeXkvjtHejID0lKzVioMfTmuXaM";
   Issuer   : constant String := "https://cmpnlt-demo.eu.auth0.com/";
   Key_Data : String := Read_File ("tests/data/HTTP_auth_key.json");

   Server_Address   : Sock_Addr_Type;
   Upstream_Address : Sock_Addr_Type;

   -- Do not perform validation
   Passthrough : Boolean := False;

   Error_HTML : constant String :=
      "<HTML><BODY><H1>Unauthorized request. Please login.</H1></BODY></HTML>";

   --  FIXME: Warning: This is dangerous, use Ada function to retrieve time
   type Time_t is new Long_Integer;
   procedure Time (Time : in out Time_t);
   pragma import (C, Time);

   -------------------
   -- Error_Message --
   -------------------

   function Error_Message (Input : String) return String
   is
   begin
      return
         "HTTP/1.1 401 Unauthorized"
         & ASCII.CR & ASCII.LF &
         "Connection: Keep-Alive"
         & ASCII.CR & ASCII.LF &
         "Content-Length:" & Input'Length'Img
         & ASCII.CR & ASCII.LF
         & ASCII.CR & ASCII.LF
         & Input;
   end Error_Message;

   -----------
   -- Proxy --
   -----------

   task type Proxy 
   is
      entry Setup (S : Socket_Type);
   end Proxy;

   task body Proxy
   is
      Server_Socket   : Socket_Type;
      Upstream_Socket : Socket_Type;

      Read_Set  : Socket_Set_Type;
      Write_Set : Socket_Set_Type;
      Selector  : Selector_Type;
      Status    : Selector_Status;
      Request   : Request_Type (N_Bytes_To_Read);

      package HA is new JWX.Stream_Auth (Key_Data => Key_Data,
                                         Audience => Audience,
                                         Issuer   => Issuer);
      use HA;

      Auth : Auth_Result_Type := Auth_Invalid;
      Now : Time_t := 0;
   begin
      accept Setup (S : Socket_Type)
      do
         Server_Socket := S;
      end;

      Create_Socket (Socket => Upstream_Socket);
      Connect_Socket (Socket => Upstream_Socket,
                      Server => Upstream_Address);

      -- Initialized socket set
      Empty (Read_Set);
      Empty (Write_Set);

      Create_Selector (Selector);

      loop
         Set (Read_Set, Server_Socket);
         Set (Read_Set, Upstream_Socket);
         Check_Selector (Selector, Read_Set, Write_Set, Status);

         case Status is
            when Completed =>
               if Is_Set (Read_Set, Server_Socket)
               then
                  Control_Socket (Server_Socket, Request);
                  if Request.Size = 0
                  then
                     -- Server socket was closed, close upstream socket
                     Close_Socket (Upstream_Socket);
                     Close_Socket (Server_Socket);
                     exit;
                  end if;
                  declare
                     Buffer : String (1 .. Request.Size);
                  begin
                     String'Read (Stream (Server_Socket), Buffer);
                     if Auth /= Auth_OK and not Passthrough
                     then
                        Time (Now);
                        Auth := Authenticated (Buffer, Long_Integer (Now));
                        if Auth /= Auth_OK
                        then
                           String'Write (Stream (Server_Socket), Error_Message (Error_HTML));
                           Close_Socket (Upstream_Socket);
                           Close_Socket (Server_Socket);
                           exit;
                        end if;
                     end if;
                     String'Write (Stream (Upstream_Socket), Buffer);
                  end;
               elsif Is_Set (Read_Set, Upstream_Socket)
               then
                  Control_Socket (Upstream_Socket, Request);
                  if Request.Size = 0
                  then
                     -- Upstream socket was closed, close server socket
                     Close_Socket (Upstream_Socket);
                     Close_Socket (Server_Socket);
                     exit;
                  end if;
                  declare
                     Buffer : String (1 .. Request.Size);
                  begin
                     String'Read (Stream (Upstream_Socket), Buffer);
                     if Passthrough or Auth = Auth_OK
                     then
                        String'Write (Stream (Server_Socket), Buffer);
                     end if;
                  end;
               end if;

            when Expired => Put_Line ("Expired");
            when Aborted => Put_Line ("Aborted");
         end case;
      end loop;

      Close_Selector (Selector);
      Put (ASCII.BS);

   end Proxy;

   procedure Print_Usage
   is
   begin
      Put_Line ("authproxy [--local LOCAL_ADDRESS] [--lport LOCAL_PORT] [--upstream UPSTREAM_ADDRESS] [--uport UPSTREAM_PORT] [--passthrough]");
   end Print_Usage;

   function Handle_Command_Line return Boolean
   is
      Server_IP     : access String := new String'("127.0.3.1");
      Server_Port   : Port_Type     := 8080;
      Upstream_IP   : access String := new String'("127.0.0.1");
      Upstream_Port : Port_Type     := 80;
      S : Character;
   begin
      loop
         begin
            S := Getopt ("-local= -lport= -upstream= -uport= -passthrough -help");
         exception
            when others =>
               Print_Usage;
               return False;
         end;

         case S
         is
            when '-' =>
               if Full_Switch = "-local"
               then
                  Server_IP := new String'(Parameter);
               elsif Full_Switch = "-lport"
               then
                  Server_Port := Port_Type'Value (Parameter);
               elsif Full_Switch = "-upstream"
               then
                  Upstream_IP := new String'(Parameter);
               elsif Full_Switch = "-uport"
               then
                  Upstream_Port := Port_Type'Value (Parameter);
               elsif Full_Switch = "-passthrough"
               then
                  Put_Line ("WARNING: RUNNING IN *PASSTHROUGH* MODE!");
                  Passthrough := True;
               elsif Full_Switch = "-help"
               then
                  Print_Usage;
                  return False;
               end if;
            when others =>
               exit;
         end case;
      end loop;

      Server_Address :=
         (Family => Family_Inet,
          Addr   => Inet_Addr (Server_IP.all),
          Port   => Server_Port);

      Upstream_Address :=
         (Family => Family_Inet,
          Addr   => Inet_Addr (Upstream_IP.all),
          Port   => Upstream_Port);

      return True;

   end Handle_Command_Line;

   P : access Proxy;

begin

   if not Handle_Command_Line
   then
      return;
   end if;

   Put_Line ("Forwarding " & Image (Server_Address) & " <=> " & Image (Upstream_Address));
   Initialize;
   Create_Socket (Socket => Server_Socket);
   Set_Socket_Option
      (Socket => Server_Socket,
       Level  => Socket_Level,
       Option => (Name => Reuse_Address, Enabled => True));
   Bind_Socket
      (Socket  => Server_Socket,
       Address => Server_Address);
   Listen_Socket (Socket => Server_Socket);

   loop
      Accept_Socket
         (Server  => Server_Socket,
          Socket  => Client_Socket,
          Address => Client_Address);
      Put (".");
      P := new Proxy; 
      P.Setup (Client_Socket);
   end loop;
end Authproxy;
