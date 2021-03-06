{-# LANGUAGE ImplicitParams #-}
{-# LANGUAGE QuasiQuotes #-}

module Main where

import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BS8
import qualified Data.Map as Map

import Text.Heredoc (there)

import qualified Cryptol.ModuleSystem.Name as N
import qualified Cryptol.Utils.Ident as N

import qualified Verifier.SAW.Cryptol as C
import           Verifier.SAW.SharedTerm
import qualified Verifier.SAW.SCTypeCheck as TC
import qualified Verifier.SAW.Cryptol.Prelude as C
import qualified Verifier.SAW.CryptolEnv as CEnv

main :: IO ()
main =
  do sc <- mkSharedContext
     C.scLoadPreludeModule sc
     C.scLoadCryptolModule sc
     putStrLn "Loaded Cryptol.sawcore!"
     let ?fileReader = BS.readFile
     cenv0 <- CEnv.initCryptolEnv sc
     putStrLn "Translated Cryptol.cry!"
     cenv1 <- CEnv.importModule sc cenv0 (Right N.floatName) Nothing Nothing
     putStrLn "Translated Float.cry!"
     cenv2 <- CEnv.importModule sc cenv1 (Right N.arrayName) Nothing Nothing
     putStrLn "Translated Array.cry!"
     cenv3 <- CEnv.parseDecls sc cenv2 (CEnv.InputText superclassContents "superclass.cry" 1 1)
     putStrLn "Translated superclass.cry!"
     cenv4 <- CEnv.parseDecls sc cenv3 (CEnv.InputText instanceContents "instance.cry" 1 1)
     putStrLn "Translated instance.cry!"
     mapM_ (checkTranslation sc) $ Map.assocs (CEnv.eTermEnv cenv4)
     putStrLn "Checked all terms!"

checkTranslation :: SharedContext -> (N.Name, Term) -> IO ()
checkTranslation sc (name, term) =
  do result <- TC.scTypeCheck sc Nothing term
     case result of
       Right _ -> pure ()
       Left err ->
         do putStrLn $ "Type error when checking " ++ show (N.unpackIdent (N.nameIdent name))
            putStrLn $ unlines $ TC.prettyTCError err
            fail "internal type error"

superclassContents :: String
superclassContents = [there|test/superclass.cry|]

instanceContents :: String
instanceContents = [there|test/instance.cry|]
