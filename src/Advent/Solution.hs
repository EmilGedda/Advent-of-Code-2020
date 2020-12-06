module Advent.Solution where

import Advent.Problem           (Day(..), Input, fetchInput)
import Advent.API               (currentYear)
import Control.Monad.Except     (runExceptT)
import Data.Maybe               (isNothing, fromJust)
import Data.List                (find)

import Advent.Solution.DayOne   (day1)
import Advent.Solution.DayTwo   (day2)
import Advent.Solution.DayThree (day3)
import Advent.Solution.DayFour  (day4)
import Advent.Solution.DayFive  (day5)
import Advent.Solution.DaySix   (day6)

days :: [Day]
days = [
        day1,
        day2,
        day3,
        day4,
        day5,
        day6
    ]

solveDay :: Day -> Input -> IO ()
solveDay (Day d partOne partTwo) input = do
    putStrLn $ "Solving day " ++ show d
    putStrLn . (++) "Part 1: " . partOne $ input
    putStrLn . (++) "Part 2: " . partTwo $ input

solve :: Integer -> IO ()
solve day | isNothing solution = putStrLn $ "No solution for day " ++ show day
          | otherwise = do
        year  <- currentYear
        input <- runExceptT $ fetchInput year day
        either putStrLn (solveDay $ fromJust solution) input
    where solution = find ((==) day . number) days

