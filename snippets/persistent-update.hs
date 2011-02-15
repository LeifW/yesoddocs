-- START
{-# LANGUAGE QuasiQuotes, TypeFamilies, GeneralizedNewtypeDeriving #-}
import Database.Persist
import Database.Persist.Sqlite
import Database.Persist.TH
import Data.Time

share [mkPersist, mkMigrate "migrateAll"] [$persist|
Person
    name String Eq Update
    age Int Gt
|]

main = withSqliteConn ":memory:" $ runSqlConn $ do
    runMigration migrateAll
    updateWhere
        [ PersonNameEq "Michael"
        , PersonAgeGt 25
        ]
        [ PersonName "Mike"
        ]
-- STOP
