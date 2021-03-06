{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}

import Advent
import Advent.API
import Advent.Problem
import Solutions

import Gauge.Main

import Control.Monad.Except   (runExceptT, ExceptT(..), MonadError)
import Control.Monad.Reader   (ReaderT)
import Control.Monad.Catch    (MonadCatch)

type App r a = ReaderT r (ExceptT String IO) a
type MonadApp m = (MonadHTTP m, MonadError String m, MonadCatch m, MonadFS m)

output :: (a -> IO (Either String b)) -> (b -> IO ()) -> a -> IO ()
output f g input = either putStrLn g =<< f input

(<==) :: (a -> IO ()) -> App NetworkEnv a -> IO ()
(<==) = output $ runExceptT . runNetworkEnv
infixr 0 <==

main :: IO ()
main = defaultMain <== mapM (\(WrapYear y) -> benchYear y) years

benchYear :: MonadApp m => Year _ _ -> m Benchmark
benchYear y@(Year solutions) = do
    let days = toDayList solutions
    years  <- mapM (\(WrapDay d) -> benchDay (yearNum y) d) days
    return $ bgroup (('Y':) . show $ yearNum y) years

benchDay :: MonadApp m => Integer -> Day _ -> m Benchmark
benchDay year d@(Day partOne partTwo) = do
    Input input <- fetchInput year (dayNum d)
    let text = parseInput input
    return $ bgroup (('D':) . show $ dayNum d)
                    [ bench "Silver" $ nf partOne text
                    , bench "Gold"   $ nf partTwo text
                    ]
