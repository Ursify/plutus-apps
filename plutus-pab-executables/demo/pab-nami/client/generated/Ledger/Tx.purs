-- File auto generated by purescript-bridge! --
module Ledger.Tx where

import Prelude

import Control.Lazy (defer)
import Data.Argonaut (encodeJson, jsonNull)
import Data.Argonaut.Decode (class DecodeJson)
import Data.Argonaut.Decode.Aeson ((</$\>), (</*\>), (</\>))
import Data.Argonaut.Encode (class EncodeJson)
import Data.Argonaut.Encode.Aeson ((>$<), (>/\<))
import Data.Either (Either)
import Data.Generic.Rep (class Generic)
import Data.Lens (Iso', Lens', Prism', iso, prism')
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Lens.Record (prop)
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.RawJson (RawJson)
import Data.Show.Generic (genericShow)
import Data.Tuple.Nested ((/\))
import Plutus.V1.Ledger.Address (Address)
import Plutus.V1.Ledger.Scripts (DatumHash, Validator)
import Plutus.V1.Ledger.Tx (Tx)
import Plutus.V1.Ledger.Value (Value)
import Type.Proxy (Proxy(Proxy))
import Data.Argonaut.Decode.Aeson as D
import Data.Argonaut.Encode.Aeson as E
import Data.Map as Map

data CardanoTx
  = EmulatorTx Tx
  | CardanoApiTx RawJson
  | Both Tx RawJson

derive instance Eq CardanoTx

instance Show CardanoTx where
  show a = genericShow a

instance EncodeJson CardanoTx where
  encodeJson = defer \_ -> case _ of
    EmulatorTx a -> E.encodeTagged "EmulatorTx" a E.value
    CardanoApiTx a -> E.encodeTagged "CardanoApiTx" a E.value
    Both a b -> E.encodeTagged "Both" (a /\ b) (E.tuple (E.value >/\< E.value))

instance DecodeJson CardanoTx where
  decodeJson = defer \_ -> D.decode
    $ D.sumType "CardanoTx"
    $ Map.fromFoldable
        [ "EmulatorTx" /\ D.content (EmulatorTx <$> D.value)
        , "CardanoApiTx" /\ D.content (CardanoApiTx <$> D.value)
        , "Both" /\ D.content (D.tuple $ Both </$\> D.value </*\> D.value)
        ]

derive instance Generic CardanoTx _

--------------------------------------------------------------------------------

_EmulatorTx :: Prism' CardanoTx Tx
_EmulatorTx = prism' EmulatorTx case _ of
  (EmulatorTx a) -> Just a
  _ -> Nothing

_CardanoApiTx :: Prism' CardanoTx RawJson
_CardanoApiTx = prism' CardanoApiTx case _ of
  (CardanoApiTx a) -> Just a
  _ -> Nothing

_Both :: Prism' CardanoTx { a :: Tx, b :: RawJson }
_Both = prism' (\{ a, b } -> (Both a b)) case _ of
  (Both a b) -> Just { a, b }
  _ -> Nothing

--------------------------------------------------------------------------------

data ChainIndexTxOut
  = PublicKeyChainIndexTxOut
      { _ciTxOutAddress :: Address
      , _ciTxOutValue :: Value
      }
  | ScriptChainIndexTxOut
      { _ciTxOutAddress :: Address
      , _ciTxOutValidator :: Either String Validator
      , _ciTxOutDatum :: Either DatumHash String
      , _ciTxOutValue :: Value
      }

derive instance Eq ChainIndexTxOut

instance Show ChainIndexTxOut where
  show a = genericShow a

instance EncodeJson ChainIndexTxOut where
  encodeJson = defer \_ -> case _ of
    PublicKeyChainIndexTxOut { _ciTxOutAddress, _ciTxOutValue } -> encodeJson
      { tag: "PublicKeyChainIndexTxOut"
      , _ciTxOutAddress: flip E.encode _ciTxOutAddress E.value
      , _ciTxOutValue: flip E.encode _ciTxOutValue E.value
      }
    ScriptChainIndexTxOut { _ciTxOutAddress, _ciTxOutValidator, _ciTxOutDatum, _ciTxOutValue } -> encodeJson
      { tag: "ScriptChainIndexTxOut"
      , _ciTxOutAddress: flip E.encode _ciTxOutAddress E.value
      , _ciTxOutValidator: flip E.encode _ciTxOutValidator (E.either E.value E.value)
      , _ciTxOutDatum: flip E.encode _ciTxOutDatum (E.either E.value E.value)
      , _ciTxOutValue: flip E.encode _ciTxOutValue E.value
      }

instance DecodeJson ChainIndexTxOut where
  decodeJson = defer \_ -> D.decode
    $ D.sumType "ChainIndexTxOut"
    $ Map.fromFoldable
        [ "PublicKeyChainIndexTxOut" /\
            ( PublicKeyChainIndexTxOut <$> D.object "PublicKeyChainIndexTxOut"
                { _ciTxOutAddress: D.value :: _ Address
                , _ciTxOutValue: D.value :: _ Value
                }
            )
        , "ScriptChainIndexTxOut" /\
            ( ScriptChainIndexTxOut <$> D.object "ScriptChainIndexTxOut"
                { _ciTxOutAddress: D.value :: _ Address
                , _ciTxOutValidator: (D.either D.value D.value) :: _ (Either String Validator)
                , _ciTxOutDatum: (D.either D.value D.value) :: _ (Either DatumHash String)
                , _ciTxOutValue: D.value :: _ Value
                }
            )
        ]

derive instance Generic ChainIndexTxOut _

--------------------------------------------------------------------------------

_PublicKeyChainIndexTxOut :: Prism' ChainIndexTxOut { _ciTxOutAddress :: Address, _ciTxOutValue :: Value }
_PublicKeyChainIndexTxOut = prism' PublicKeyChainIndexTxOut case _ of
  (PublicKeyChainIndexTxOut a) -> Just a
  _ -> Nothing

_ScriptChainIndexTxOut :: Prism' ChainIndexTxOut { _ciTxOutAddress :: Address, _ciTxOutValidator :: Either String Validator, _ciTxOutDatum :: Either DatumHash String, _ciTxOutValue :: Value }
_ScriptChainIndexTxOut = prism' ScriptChainIndexTxOut case _ of
  (ScriptChainIndexTxOut a) -> Just a
  _ -> Nothing
