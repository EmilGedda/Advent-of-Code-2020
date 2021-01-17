module Advent.Problem.Util where

import           Advent.Problem.Types                      (CommaList(..))
import           Control.Arrow                             (Arrow, (***))
import           Control.Monad                             (foldM)
import           Data.ByteString                           (ByteString)
import           Data.Monoid                               (Sum(..), getSum)
import           Data.List                                 (foldl1')
import           Debug.Trace                               (trace)
import           Data.Attoparsec.ByteString.Char8   hiding (takeWhile)
import qualified Data.Set                           as     Set

every :: Int -> [a] -> [a]
every n = map head . takeWhile (not . null) . iterate (drop n)

count :: (Foldable t, Enum b) => (a -> b) -> t a -> Int
count f = getSum . foldMap (Sum . fromEnum . f)

fromRight :: Either a b -> b
fromRight (Right r) = r
fromRight _ = error "Left in fromRight"

fromBool :: (a -> Bool) -> a -> Maybe a
fromBool f x | f x = Just x
             | otherwise = Nothing

between :: Ord a => a -> a -> a -> Bool
between a b x = a <= x && x <= b

both :: Arrow a => a b c -> a (b, b) (c, c)
both f = f *** f

sortNub :: (Ord a) => [a] -> [a]
sortNub = Set.toList . Set.fromList

same :: (Eq a) => [a] -> Bool
same xs = all (== head xs) (tail xs)

fromBits :: Num a => [a] -> a
fromBits = foldl1' ((+) . (2*))

fold :: (Foldable t, Monad m) => t a -> b -> (b -> a -> m b) -> m b
fold v s f = foldM f s v

commalist :: Parser a -> Parser (CommaList a)
commalist p = CommaList <$> p `sepBy` char ','

debug :: Show a => a -> a
debug x = trace (show x) x

digits :: Integral x => x -> [x]
digits = reverse . go
    where go 0 = []
          go x = x `mod` 10 : go (x `div` 10)

attoparse :: Parser a -> ByteString -> a
attoparse p = fromRight . parseOnly p
