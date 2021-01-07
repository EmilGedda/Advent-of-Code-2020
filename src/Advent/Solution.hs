{-# LANGUAGE BangPatterns #-}
module Advent.Solution where

import Advent.Problem            (Day(..), Input, fetchInput, fromInput, parseInput, solution)
import Advent.API                (currentYear)
import Control.Monad.Except      (runExceptT)
import Data.Maybe                (isNothing, fromJust)
import Data.List                 (find)

import Advent.Solution.DayOne       (day1)
import Advent.Solution.DayTwo       (day2)
import Advent.Solution.DayThree     (day3)
import Advent.Solution.DayFour      (day4)
import Advent.Solution.DayFive      (day5)
import Advent.Solution.DaySix       (day6)
import Advent.Solution.DaySeven     (day7)
import Advent.Solution.DayEight     (day8)
import Advent.Solution.DayNine      (day9)
import Advent.Solution.DayTen       (day10)
import Advent.Solution.DayEleven    (day11)
import Advent.Solution.DayTwelve    (day12)
import Advent.Solution.DayThirteen  (day13)
import Advent.Solution.DayFourteen  (day14)
import Advent.Solution.DayFifteen   (day15)
import Advent.Solution.DaySixteen   (day16)
import Advent.Solution.DaySeventeen (day17)
import Advent.Solution.DayEighteen  (day18)

days :: [Day]
days = [
        day1,
        day2,
        day3,
        day4,
        day5,
        day6,
        day7,
        day8,
        day9,
        day10,
        day11,
        day12,
        day13,
        day14,
        day15,
        day16,
        day17,
        day18
    ]

solveDay :: Day -> Input -> IO ()
solveDay Day{ number=d, partOne=first, partTwo=second } !text = do
    putStrLn $ "Parsing day " ++ show d
    let input = parseInput $ fromInput text
    putStrLn $ "Parsing 1: " ++ solution (first input)
    putStrLn $ "Parsing 2: " ++ solution (second input)


solve :: Integer -> IO ()
solve day | isNothing solution = putStrLn $ "No solution for day " ++ show day
          | otherwise = do
        year  <- currentYear
        input <- runExceptT $ fetchInput year day
        either putStrLn (solveDay $ fromJust solution) input
    where solution = find ((==) day . number) days

