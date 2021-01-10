module Main where

import Advent.API
import Advent.SVG
import Advent.Problem
import Advent.Leaderboard

import           Control.Monad.Except   (runExceptT, ExceptT(..), mapExceptT)
import           Control.Monad.Catch    (MonadCatch)
import           Control.Monad.Reader   (ReaderT)
import           Data.Bool              (bool)
import           Data.Char              (toLower)
import           Data.List              (partition, intercalate)
import           Data.Maybe             (fromMaybe)
import           Network.Wreq.Session   (Session)
import           Network.HTTP.Client    (CookieJar)
import           Options.Applicative
import qualified Data.ByteString.Char8  as B
import qualified Data.Map               as M

type App a = ReaderT Session (ExceptT String IO) a

data LeaderboardOrder = LocalScore | Stars

data Options = LeaderboardOptions {
                lid :: Maybe Integer,
                year :: Maybe Integer,
                order :: User -> Integer
            } | ProgressOptions {
                onlyStarCount :: Bool
            } | BadgesOptions {
                color :: Color
            }

colorReader :: ReadM Color
colorReader = eitherReader $ \s ->
        maybe (Left $ help s) Right $ map toLower s `lookup` order
        where order = [("gold", Gold), ("silver", Silver)]
              help s = "Could not parser color \"" ++ s
                       ++ "\", expected one of: " ++ intercalate ", " (map fst order)


orderReader :: ReadM (User -> Integer)
orderReader = eitherReader $ \s ->
        maybe (Left $ help s) Right $ map toLower s `lookup` order
        where order = [("localscore", localScore), ("stars", stars)]
              help s = "Could not parser order \"" ++ s
                       ++ "\", expected one of: " ++ intercalate ", " (map fst order)


leaderboardParser :: Parser Options
leaderboardParser = LeaderboardOptions
        <$> optional
                (option auto
                    (long "id"
                    <> short 'i'
                    <> metavar "ID"
                    <> help ("Leaderboard ID. Defaults to the private leaderboard "
                            ++ "of the current user. Global leaderboard not supported.")))
        <*> optional
                (option auto
                    (long "year"
                    <> short 'y'
                    <> metavar "YEAR"
                    <> help "Year of Leaderboard. Defaults to current year."))
        <*> option orderReader
                    (long "order"
                    <> short 'o'
                    <> metavar "ORDER"
                    <> value stars
                    <> help ("Scoring order, can be \"localscore\" or \"stars\". "
                          ++ "Defaults to stars. Ties are resolved by recency of last star."))

progressParser :: Parser Options
progressParser = ProgressOptions
        <$> switch
                (long "short"
                <> short 's'
                <> help "Only display gold and silver star counts")


badgesParser :: Parser Options
badgesParser = BadgesOptions
        <$> argument colorReader
                (help "Color of star to generate. Gold or silver."
                <> metavar "COLOR")

optionsParser :: Parser Options
optionsParser = subparser $
    command "badge"       (badgesParser      `withInfo` "Generate a badge from current user progress") <>
    command "leaderboard" (leaderboardParser `withInfo` "Display a leaderboard") <>
    command "progress"    (progressParser    `withInfo` "Show current user progress")

withInfo :: Parser a -> String -> ParserInfo a
withInfo opts desc = info (helper <*> opts) $ progDesc desc


main :: IO ()
main = run =<< customExecParser (prefs showHelpOnError)
    (optionsParser `withInfo` "Display info and stats from Advent of Code")


output :: (a -> ExceptT String IO b) -> (b -> IO ()) -> a -> IO ()
output f g input = either putStrLn g
  =<< (runExceptT . f) input

(<==) = output runSession
infixr 0 <==

(<<=) = output runCookies
infixr 0 <<=

toOrder :: LeaderboardOrder -> (User -> Integer)
toOrder LocalScore = localScore
toOrder Stars = stars

getID :: Maybe Integer -> User -> Integer
getID override = flip fromMaybe override . userid

current :: App (Integer, User)
current = (,) <$> currentYear <*> currentUser

run :: Options -> IO ()
run (LeaderboardOptions id year order)
  = printLeaderboard order <== do
        now <- currentYear
        id' <- maybe currentUserID return id
        leaderboard (fromMaybe now year) id'

run (ProgressOptions onlyStarCount)
    | onlyStarCount = printStars . starCount <== currentUser
    | otherwise = printLeaderboard stars <== do
        now <- currentYear
        id <- currentUserID
        soloboard <- leaderboard now id
        return $ soloboard { members = filter ((==) id . userid) (members soloboard) }
    where printStars (silver, gold) = do
            putStr "Silver\t"
            print silver
            putStr "Gold\t"
            print gold

run (BadgesOptions color)
  = B.putStrLn
  . badge color
  . bool snd fst (color == Silver)
  . starCount
  <<= currentUser -- session seems to break if used here
