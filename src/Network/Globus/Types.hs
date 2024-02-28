module Network.Globus.Types where

import Data.Aeson (ToJSON (..), Value (..))
import Data.Proxy (Proxy (..))
import Data.Tagged
import Data.Text (Text, pack)
import Data.Text qualified as Text
import Data.Text.Encoding (decodeUtf8, encodeUtf8)
import GHC.IsList (IsList (..))
import GHC.TypeLits
import Network.HTTP.Req as Req
import Network.HTTP.Types (urlEncode)
import Web.HttpApiData (toQueryParam)


type Token a = Tagged a Text
type Id a = Tagged a Text


data Token'
  = ClientId
  | ClientSecret
  | Exchange
  | Access


data Id'
  = Submission
  | Task
  | Request
  | Collection


data DataType (s :: Symbol) = DataType


instance (KnownSymbol s) => ToJSON (DataType s) where
  toJSON _ = String $ pack $ symbolVal @s Proxy


data Endpoint
  = Redirect
  | Authorization
  | Tokens


-- | Simple URI Type, since all the others are obnoxious
data Uri (a :: Endpoint) = Uri
  { scheme :: Scheme
  , domain :: Text
  , path :: [Text]
  , params :: Query
  }


renderUri :: Uri a -> Text
renderUri u =
  scheme <> endpoint <> path <> query
 where
  scheme =
    case u.scheme of
      Http -> "http://"
      Https -> "https://"
  endpoint = cleanSlash u.domain
  path = "/" <> Text.intercalate "/" (map cleanSlash u.path)
  query =
    case renderQuery u.params of
      "" -> ""
      q -> "?" <> q
  cleanSlash = Text.dropWhileEnd (== '/') . Text.dropWhile (== '/')


instance Show (Uri a) where
  show = Text.unpack . renderUri


newtype Query = Query [(Text, Maybe Text)]
  deriving newtype (Monoid, Semigroup)


instance Show Query where
  show = Text.unpack . renderQuery


instance IsList Query where
  type Item Query = (Text, Maybe Text)
  fromList = Query
  toList (Query ps) = ps


instance Req.QueryParam Query where
  queryParam t ma = Query [(t, toQueryParam <$> ma)]
  queryParamToList (Query ps) = ps


renderQuery :: Query -> Text
renderQuery (Query ps) = Text.intercalate "&" $ map toText ps
 where
  toText (p, Nothing) = p
  toText (p, Just v) = p <> "=" <> value v

  value = decodeUtf8 . urlEncode True . encodeUtf8


data Scope
  = -- TODO: figure out all scopes and hard-code
    TransferAll


scopeText :: Scope -> Text
scopeText TransferAll = "urn:globus:auth:scope:transfer.api.globus.org:all"


scope :: Text -> Maybe Scope
scope "urn:globus:auth:scope:transfer.api.globus.org:all" = Just TransferAll
scope _ = Nothing