{-# LANGUAGE DataKinds          #-}
{-# LANGUAGE DeriveAnyClass     #-}
{-# LANGUAGE DeriveGeneric      #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE NamedFieldPuns     #-}
{-# LANGUAGE NoImplicitPrelude  #-}
{-# LANGUAGE TemplateHaskell    #-}
{-# LANGUAGE TypeApplications   #-}
-- | State machine that manages credential tokens
module Plutus.Contracts.Prism.StateMachine(
    IDState(..)
    , IDAction(..)
    , UserCredential(..)
    , typedValidator
    , machineClient
    , mkMachineClient
    ) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Hashable (Hashable)
import GHC.Generics (Generic)
import Ledger.Address (PaymentPubKeyHash)
import Ledger.Constraints qualified as Constraints
import Ledger.Constraints.TxConstraints (TxConstraints)
import Ledger.Typed.Scripts qualified as Scripts
import Plutus.Contract.StateMachine (State (..), StateMachine (..), StateMachineClient (..), Void)
import Plutus.Contract.StateMachine qualified as StateMachine
import Plutus.Contracts.Prism.Credential (Credential (..), CredentialAuthority (..))
import Plutus.Contracts.Prism.Credential qualified as Credential
import Plutus.Script.Utils.V2.Typed.Scripts qualified as V2
import Plutus.Script.Utils.Value (TokenName, Value)
import PlutusTx qualified
import PlutusTx.Prelude
import Prelude qualified as Haskell

data IDState =
    Active -- ^ The credential is active and can be used in transactions
    | Revoked -- ^ The credential has been revoked and can't be used anymore.
    deriving stock (Generic, Haskell.Eq, Haskell.Show)
    deriving anyclass (ToJSON, FromJSON)

data IDAction =
    PresentCredential -- ^ Present the credential in a transaction
    | RevokeCredential -- ^ Revoke the credential
    deriving stock (Generic, Haskell.Eq, Haskell.Show)
    deriving anyclass (ToJSON, FromJSON)

-- | A 'Credential' issued to a user (public key address)
data UserCredential =
    UserCredential
        { ucAddress    :: PaymentPubKeyHash
        -- ^ Address of the credential holder
        , ucCredential ::  Credential
        -- ^ The credential
        , ucToken      :: Value
        -- ^ The 'Value' containing a token of the credential
        -- (this needs to be included here because 'Credential.token'
        -- is not available in on-chain code)
        } deriving stock (Haskell.Eq, Haskell.Show, Generic)
          deriving anyclass (ToJSON, FromJSON, Hashable)

{-# INLINABLE transition #-}
transition :: UserCredential -> State IDState -> IDAction -> Maybe (TxConstraints Void Void, State IDState)
transition UserCredential{ucAddress, ucCredential, ucToken} State{stateData=state, stateValue=currentValue} input =
    case (state, input) of
        (Active, PresentCredential) ->
            Just
                ( Constraints.mustBeSignedBy ucAddress
                , State{stateData=Active,stateValue=currentValue}
                )
        (Active, RevokeCredential) ->
            Just
                ( Constraints.mustBeSignedBy (unCredentialAuthority $ credAuthority ucCredential)
                <> Constraints.mustMintValue (inv ucToken) -- Destroy the token
                , State{stateData=Revoked, stateValue=mempty}
                )
        _ -> Nothing

{-# INLINABLE credentialStateMachine #-}
credentialStateMachine ::
  UserCredential
  -> StateMachine IDState IDAction
credentialStateMachine cd = StateMachine.mkStateMachine Nothing (transition cd) isFinal where
  isFinal Revoked = True
  isFinal _       = False

typedValidator ::
  UserCredential
  -> Scripts.TypedValidator (StateMachine IDState IDAction)
typedValidator credentialData =
    let val = $$(PlutusTx.compile [|| validator ||]) `PlutusTx.applyCode` PlutusTx.liftCode credentialData
        validator d = StateMachine.mkValidator (credentialStateMachine d)
        wrap = Scripts.mkUntypedValidator @Scripts.ScriptContextV2 @IDState @IDAction
    in V2.mkTypedValidator @(StateMachine IDState IDAction) val $$(PlutusTx.compile [|| wrap ||])

machineClient ::
    Scripts.TypedValidator (StateMachine IDState IDAction)
    -> UserCredential
    -> StateMachineClient IDState IDAction
machineClient inst credentialData =
    let machine = credentialStateMachine credentialData
    in StateMachine.mkStateMachineClient (StateMachine.StateMachineInstance machine inst)

mkMachineClient :: CredentialAuthority -> PaymentPubKeyHash -> TokenName -> StateMachineClient IDState IDAction
mkMachineClient authority credentialOwner tokenName =
    let credential = Credential{credAuthority=authority,credName=tokenName}
        userCredential =
            UserCredential
                { ucAddress = credentialOwner
                , ucCredential = credential
                , ucToken = Credential.token credential
                }
    in machineClient (typedValidator userCredential) userCredential

PlutusTx.makeLift ''UserCredential
PlutusTx.makeLift ''IDState
PlutusTx.makeLift ''IDAction
PlutusTx.unstableMakeIsData ''IDState
PlutusTx.unstableMakeIsData ''IDAction
