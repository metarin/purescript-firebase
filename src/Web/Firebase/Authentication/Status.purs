module Web.Firebase.Authentication.Status (
UserCredentials(..)
) where

import Data.Generic.Rep (class Generic)
import Data.Show.Generic (genericShow)
import Data.Eq.Generic (genericEq)
import Data.Maybe (Maybe)
import Prelude (class Eq, class Show)
import Web.Firebase.Authentication.Google (GoogleProfile)

-- | convert authdata (from twitter and google to start with) to a purescript authdata record
-- sample data at https://boiling-heat-7831.firebaseapp.com/authspike.html
-- Maybe we should use an extensible record with an alternative parser, that parses UserCredentials + google/twitter etc
-- because now users have to include all providers in their source, even when they use only one.
newtype UserCredentials = UserCredentials {
    provider :: String
  , uid :: String
  , token :: String
  , google :: Maybe GoogleProfile
}

-- ProviderUserProfile = TwitterProfile TwitterProfileRecord | GoogleProfile GoogleProfileRecord | etc

derive instance genericUserCredentials :: Generic UserCredentials _

instance showUserCredentials :: Show UserCredentials where
  show = genericShow

instance eqUserCredentials :: Eq UserCredentials where
  eq = genericEq
