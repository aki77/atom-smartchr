selectorForScopes = (selectors, scopes) ->
  for selector in selectors
    for scope in scopes
      return selector if selector.matches(scope)
  null

selectorsMatchScopes = (selectors, scopes) ->
  selectorForScopes(selectors, scopes)?

module.exports = {selectorsMatchScopes, selectorForScopes}
