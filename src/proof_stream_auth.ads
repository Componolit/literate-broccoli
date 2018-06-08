--
-- \brief  Helper package for proving generic JWX.Stream_Auth
-- \author Alexander Senier
-- \date   2018-06-07
--
-- Copyright (C) 2018 Componolit GmbH
--
-- This file is part of JWX, which is distributed under the terms of the
-- GNU Affero General Public License version 3.
--

with JWX.Stream_Auth;

package Proof_Stream_Auth
with
   SPARK_Mode
is
   procedure Test (OK : out Boolean);

end Proof_Stream_Auth;