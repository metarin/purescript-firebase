module Test.WriteGenericSpec (writeGenericSpec) where

import Prelude (Unit, bind, ($), class Show, class Eq)

import Control.Monad.Aff (Aff(), launchAff)
import Control.Monad.Aff.AVar (AVAR(), AVar, makeVar, takeVar, putVar)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Exception (EXCEPTION(), message)
import Data.Maybe (Maybe(Nothing))
import Data.Either (Either(Right))
import Web.Firebase as FB
import Web.Firebase.Monad.Aff (onceValue)
import Web.Firebase.UnsafeRef (refFor)
import Web.Firebase.DataSnapshot as D
import Web.Firebase.Types as FBT
import Test.Spec                  (describe, pending, it, Spec())
import Test.Spec.Runner           (Process())
import Test.Spec.Assertions       (shouldEqual, shouldNotEqual)
import Data.Foreign.Generic -- (toForeignGeneric, readGeneric)
import Data.Generic

entriesRef :: forall eff. Aff (firebase :: FBT.FirebaseEff | eff) FBT.Firebase
entriesRef = refFor "https://purescript-spike.firebaseio.com/entries/generic"


setRef :: forall eff. Aff (firebase :: FBT.FirebaseEff | eff) FBT.Firebase
setRef = refFor "https://purescript-spike.firebaseio.com/entries/wecanset/generic/paths"

jsonOptions :: Options
jsonOptions = defaultOptions {unwrapNewtypes = true}

data MyBoolean = Yes | No | Perhaps | DontKnowYet

derive instance genericMyBoolean :: Generic MyBoolean

instance showMyBoolean :: Show MyBoolean where
  show = gShow

instance eqMyBoolean :: Eq MyBoolean where
  eq = gEq


newtype MyInvitation = MyInvitation {invitee :: String
                                , willAttend :: MyBoolean }

derive instance genericMyInvitation :: Generic MyInvitation

instance showMyInvitation :: Show MyInvitation where
  show = gShow

instance eqMyInvitation :: Eq MyInvitation where
  eq = gEq


noShow :: MyInvitation
noShow = MyInvitation {invitee: "someone", willAttend: No}

dontKnow = MyInvitation {invitee: "mr bean", willAttend: DontKnowYet }

writeGenericSpec ::  forall eff. Spec ( avar :: AVAR, firebase :: FBT.FirebaseEff, err :: EXCEPTION | eff) Unit
writeGenericSpec = do
  describe "Writing objects with toForeignGeneric" do
      it "can add an ADT to a list" do
        location <- entriesRef
        newChildRef <- liftEff $ FB.push (toForeignGeneric jsonOptions Yes) Nothing location
        snap <- onceValue newChildRef
        (D.key snap) `shouldNotEqual` Nothing
        -- key is different on every write. Checking unique keys is work for QuickCheck
        (readGeneric jsonOptions (D.val snap)) `shouldEqual` (Right Yes)
        -- use key to read value

      it "can overwrite an existing ADT" do
        let secondValue = {success: "second value"}
        location <- entriesRef
        newChildRef <- liftEff $ FB.push (toForeignGeneric jsonOptions Yes) Nothing location
        _ <- liftEff $ FB.set (toForeignGeneric jsonOptions No) Nothing newChildRef
        snap <- onceValue newChildRef
        (readGeneric jsonOptions (D.val snap)) `shouldEqual` (Right No)
      it "pushE calls back with Nothing when no error occurs" do
          location <- entriesRef
          respVar  <- makeVar
          handle  <- liftEff $ FB.pushE (toForeignGeneric jsonOptions noShow) (\err -> launchAff $ putVar respVar err) location
          actual :: Maybe FBT.FirebaseErr <- takeVar respVar
          actual `shouldEqual` Nothing
      it "setE calls back with Nothing when no error occurs" do
          location <- setRef
          respVar  <- makeVar
          liftEff $ FB.setE (toForeignGeneric jsonOptions dontKnow) (\err -> launchAff $ putVar respVar err) location
          actual :: Maybe FBT.FirebaseErr <- takeVar respVar
          actual `shouldEqual` Nothing

      pending "can overwrite an existing item in Aff"
      pending "can add a server-side timestamp to new items"
      pending "push Aff when writing to non-existant location returns an error"
      pending "Removal confirmed by subscription on()" -- baby steps
      pending "Removal not notified after subscription turned off()" -- test with timeout? how?
      -- implement AFF with error callback (it is error object or nothing, so we can make it 'or Right "write successful", which we can reuse in a value writeSuccess so we can assert against that. Not sure how to combine that with the value of the key that is also returned from the js function'
