--
-- \brief  JWX test suite
-- \author Alexander Senier
-- \date   2018-05-12
--
-- Copyright (C) 2018 Componolit GmbH
--
-- This file is part of JWX, which is distributed under the terms of the
-- GNU Affero General Public License version 3.
--

with AUnit.Test_Suites;

package JWX_Suite is
   function Suite return AUnit.Test_Suites.Access_Test_Suite;
end JWX_Suite;
