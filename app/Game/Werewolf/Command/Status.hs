{-|
Module      : Game.Werewolf.Command.Status
Description : Status commands.

Copyright   : (c) Henry J. Wylde, 2016
License     : BSD3
Maintainer  : public@hjwylde.com

Status commands.
-}

{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Game.Werewolf.Command.Status (
    -- * Commands
    circleCommand, pingCommand, statusCommand,
) where

import Control.Lens
import Control.Monad.Extra
import Control.Monad.State
import Control.Monad.Writer

import Data.Text (Text)

-- TODO (hjw): remove Message.Engine
import           Game.Werewolf
import           Game.Werewolf.Command
import           Game.Werewolf.Message.Command
import           Game.Werewolf.Message.Engine
import qualified Game.Werewolf.Role            as Role
import           Game.Werewolf.Util

circleCommand :: Text -> Bool -> Command
circleCommand callerName includeDead = Command $ do
        players' <- toListOf (players . traverse . if includeDead then id else alive) <$> get

        tell [circleMessage callerName players']

pingCommand :: Text -> Command
pingCommand callerName = Command $ use stage >>= \stage' -> case stage' of
    DruidsTurn          -> return ()
    GameOver            -> tell [gameIsOverMessage callerName]
    HuntersTurn1        -> pingRole hunterRole
    HuntersTurn2        -> pingRole hunterRole
    Lynching            -> return ()
    NecromancersTurn    -> pingRole necromancerRole
    OraclesTurn         -> pingRole oracleRole
    OrphansTurn         -> pingRole orphanRole
    ProtectorsTurn      -> pingRole protectorRole
    ScapegoatsTurn      -> pingRole scapegoatRole
    SeersTurn           -> pingRole seerRole
    Sunrise             -> return ()
    Sunset              -> return ()
    VillageDrunksTurn   -> pingRole villageDrunkRole
    VillagesTurn        -> pingVillagers
    WerewolvesTurn      -> pingWerewolves
    WitchsTurn          -> pingRole witchRole

pingRole :: (MonadState Game m, MonadWriter [Message] m) => Role -> m ()
pingRole role' = do
    player <- findPlayerBy_ role role'

    tell . (:[]) . pingRoleMessage =<< get
    tell [pingPlayerMessage $ player ^. name]
    where
        pingRoleMessage game
            | has (Role.activity . _Diurnal) role'   = pingDiurnalRoleMessage role'
            | otherwise                         = pingNocturnalRoleMessage role' game

pingVillagers :: (MonadState Game m, MonadWriter [Message] m) => m ()
pingVillagers = do
    pendingVoterNames <- toListOf (pendingVoters . name) <$> get

    tell [pingVillageMessage]
    tell $ map pingPlayerMessage pendingVoterNames

pingWerewolves :: (MonadState Game m, MonadWriter [Message] m) => m ()
pingWerewolves = do
    pendingVoterNames <- toListOf (pendingVoters . name) <$> get

    tell . (:[]) . pingWerewolvesMessage =<< get
    tell $ map pingPlayerMessage pendingVoterNames

statusCommand :: Text -> Command
statusCommand callerName = Command $ do
    game <- get

    tell [ currentStageMessage game
        , rolesInGameMessage (Just callerName) game
        , playersInGameMessage callerName game
        ]

    whenM (isPlayerDullahan callerName) $ tell [marksInGameMessage callerName game]
    where
        currentStageMessage game
            | has (stage . _GameOver) game              = gameIsOverMessage callerName
            | has (stage . activity . _Diurnal) game    = currentDiurnalTurnMessage callerName game
            | otherwise                                 = currentNocturnalTurnMessage callerName game
