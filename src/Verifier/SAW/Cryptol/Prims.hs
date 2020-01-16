{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FlexibleContexts #-}

{- |
Module      : Verifier.SAW.Cryptol
Copyright   : Galois, Inc. 2012-2015
License     : BSD3
Maintainer  : huffman@galois.com
Stability   : experimental
Portability : non-portable (language extensions)
-}

module Verifier.SAW.Cryptol.Prims
( concretePrims
, bitblastPrims
, sbvPrims
, w4Prims
) where

import Control.Monad
import Data.Map (Map)
import qualified Data.Map as Map
import qualified Data.Vector as V

import Data.AIG.Interface (IsAIG)
import qualified Data.AIG.Operations as AIG

import qualified Cryptol.TypeCheck.Solver.InfNat as CryNat

import Data.SBV.Dynamic as SBV
import What4.Interface as W4

import Verifier.SAW.TypedAST
import qualified Verifier.SAW.Prim as P
import Verifier.SAW.Simulator.Value
import Verifier.SAW.Simulator.Prims
import qualified Verifier.SAW.Simulator.BitBlast as BB
import qualified Verifier.SAW.Simulator.SBV as SBV
import qualified Verifier.SAW.Simulator.Concrete as C
import qualified Verifier.SAW.Simulator.What4 as W4
import qualified Verifier.SAW.Simulator.What4.SWord as W4

-- primitive cryError :: (a :: sort 0) -> (n :: Nat) -> Vec n (bitvector 8) -> a;
cryError :: VMonad l => (VWord l -> EvalM l Char) -> Value l
cryError asChar =
  strictFun $ \_a -> return $
  strictFun $ \_n -> return $
  strictFun $ \(VVector msgChars) -> do
    let toChar (VWord w) = asChar w
        toChar _ = fail "Cryptol.cryError: unable to print message"
    msg <- mapM (toChar <=< force) $ V.toList $ msgChars
    fail $ "Cryptol.cryError: " ++ msg

bvAsChar :: Monad m => P.BitVector -> m Char
bvAsChar w = return $ toEnum $ fromInteger $ P.unsigned $ w

aigWordAsChar :: (MonadFail m, IsAIG l g) => g s -> AIG.BV (l s) -> m Char
aigWordAsChar g bv =
  case AIG.asUnsigned g bv of
    Just i -> return $ toEnum $ fromInteger i
    Nothing -> fail "unable to interpret bitvector as character"

sbvWordAsChar :: MonadFail m => SBV.SWord -> m Char
sbvWordAsChar bv =
  case SBV.svAsInteger bv of
    Just i -> return $ toEnum $ fromInteger i
    Nothing -> fail "unable to interpret bitvector as character"

w4WordAsChar :: (MonadFail m, W4.IsExprBuilder sym) => W4.SWord sym -> m Char
w4WordAsChar bv =
  case W4.bvAsUnsignedInteger bv of   -- or signed?
    Just i -> return $ toEnum $ fromInteger i
    Nothing -> fail "unable to interpret bitvector as character"

--primitive tcLenFromThenTo_Nat :: Nat -> Nat -> Nat -> Nat;
tcLenFromThenTo_Nat :: VMonad l => Value l
tcLenFromThenTo_Nat =
  natFun' "tcLenFromThenTo_Nat x" $ \x -> return $
  natFun' "tcLenFromThenTo_Nat y" $ \y -> return $
  natFun' "tcLenFromThenTo_Nat z" $ \z ->
    case CryNat.nLenFromThenTo (CryNat.Nat $ fromIntegral x)
                               (CryNat.Nat $ fromIntegral y)
                               (CryNat.Nat $ fromIntegral z) of
      Just (CryNat.Nat ans) -> return $ vNat $ fromIntegral ans
      _ -> fail "tcLenFromThenTo_Nat: unable to calculate length"

concretePrims :: Map Ident C.CValue
concretePrims = Map.fromList
  [ ("Cryptol.ecRandom"            , error "Cryptol.ecRandom is deprecated; don't use it")
  , ("Cryptol.cryError"            , cryError bvAsChar )
  , ("Cryptol.tcLenFromThenTo_Nat" , tcLenFromThenTo_Nat )
  ]

bitblastPrims :: IsAIG l g => g s -> Map Ident (BB.BValue (l s))
bitblastPrims g = Map.fromList
  [ ("Cryptol.ecRandom"            , error "Cryptol.ecRandom is deprecated; don't use it")
  , ("Cryptol.cryError"            , cryError (aigWordAsChar g) )
  , ("Cryptol.tcLenFromThenTo_Nat" , tcLenFromThenTo_Nat )
  ]

sbvPrims :: Map Ident SBV.SValue
sbvPrims = Map.fromList
  [ ("Cryptol.ecRandom"            , error "Cryptol.ecRandom is deprecated; don't use it")
  , ("Cryptol.cryError"            , cryError sbvWordAsChar )
  , ("Cryptol.tcLenFromThenTo_Nat" , tcLenFromThenTo_Nat )
  ]


w4Prims :: W4.IsExprBuilder sym => Map Ident (W4.SValue sym)
w4Prims = Map.fromList
  [ ("Cryptol.ecRandom"            , error "Cryptol.ecRandom is deprecated; don't use it")
  , ("Cryptol.cryError"            , cryError w4WordAsChar )
  , ("Cryptol.tcLenFromThenTo_Nat" , tcLenFromThenTo_Nat )
  ]
