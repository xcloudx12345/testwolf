{-|
Module      : Werewolf.Command.Start
Description : Options and handler for the start subcommand.

Copyright   : (c) Henry J. Wylde, 2016
License     : BSD3
Maintainer  : public@hjwylde.com

Options and handler for the start subcommand.
-}

{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Werewolf.Command.Start (
    -- * Options
    Options(..), ExtraRoles(..),

    -- * Handle
    handle,
) where

import Control.Lens.Extra
import Control.Monad.Except
import Control.Monad.Extra
import Control.Monad.Random
import Control.Monad.State
import Control.Monad.Writer

import Data.Text (Text)

import           Game.Werewolf
import           Game.Werewolf.Engine
import           Game.Werewolf.Message.Error
import qualified Game.Werewolf.Variant       as Variant

import System.Random.Shuffle

import Werewolf.System

data Options = Options
    { optExtraRoles :: ExtraRoles
    , optVariant    :: Text
    , argPlayers    :: [Text]
    } deriving (Eq, Show)

data ExtraRoles = None | Random | Use [Text]
    deriving (Eq, Show)

handle :: (MonadIO m, MonadRandom m) => Text -> Text -> Options -> m ()
handle callerName tag (Options extraRoles variant playerNames) = do
    whenM (doesGameExist tag &&^ (hasn't (stage . _GameOver) <$> readGame tag)) $ exitWith failure
        { messages = [gameAlreadyRunningMessage callerName]
        }

    result <- runExceptT $ do
        extraRoles' <- case extraRoles of
            None            -> return []
            Random          -> randomExtraRoles $ length playerNames
            Use roleNames   -> useExtraRoles callerName roleNames

        variant' <- useVariant callerName variant

        let defaultVillagerRole = if is spitefulVillage variant' then spitefulVillagerRole else simpleVillagerRole
        let roles = padRoles extraRoles' (length playerNames + 1) defaultVillagerRole

        players <- createPlayers (callerName:playerNames) <$> shuffleM roles

        runWriterT $ startGame callerName variant' players >>= execStateT checkStage

    case result of
        Left errorMessages      -> exitWith failure { messages = errorMessages }
        Right (game, messages)  -> writeOrDeleteGame tag game >> exitWith success { messages = messages }

randomExtraRoles :: MonadRandom m => Int -> m [Role]
randomExtraRoles n = do
    let minimum = n `div` 4 + 1
    let maximum = n `div` 3 + 1

    count <- getRandomR (minimum, maximum)

    take count <$> shuffleM restrictedRoles

useExtraRoles :: MonadError [Message] m => Text -> [Text] -> m [Role]
useExtraRoles callerName roleNames = forM roleNames $ \roleName -> case findRoleByTag roleName of
    Just role   -> return role
    Nothing     -> throwError [roleDoesNotExistMessage callerName roleName]

findRoleByTag :: Text -> Maybe Role
findRoleByTag tag' = restrictedRoles ^? traverse . filteredBy tag tag'

useVariant :: MonadError [Message] m => Text -> Text -> m Variant
useVariant callerName variantName = case findVariantByTag variantName of
    Just variant   -> return variant
    Nothing         -> throwError [variantDoesNotExistMessage callerName variantName]

findVariantByTag :: Text -> Maybe Variant
findVariantByTag tag' = allVariants ^? traverse . filteredBy Variant.tag tag'

padRoles :: [Role] -> Int -> Role -> [Role]
padRoles roles n defaultVillagerRole = roles ++ villagerRoles ++ simpleWerewolfRoles
    where
        goal                    = 3
        m                       = max (n - length roles) 0
        startingBalance         = sumOf (traverse . balance) roles
        simpleWerewolfBalance   = simpleWerewolfRole ^. balance

        -- Little magic here to calculate how many Werewolves and Villagers we want.
        -- This tries to ensure that the balance of the game is between -3 and 2.
        simpleWerewolvesCount   = (goal - m - startingBalance) `div` (simpleWerewolfBalance - 1) + 1
        villagersCount          = m - simpleWerewolvesCount

        -- N.B., if roles is quite unbalanced then one list will be empty.
        villagerRoles       = replicate villagersCount defaultVillagerRole
        simpleWerewolfRoles = replicate simpleWerewolvesCount simpleWerewolfRole

createPlayers :: [Text] -> [Role] -> [Player]
createPlayers = zipWith newPlayer
