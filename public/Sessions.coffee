App.AuthManager = Ember.Object.extend(
    init: () ->
        @_super()
        authToken = $.cookie("auth_token")
        authAccountId = $.cookie("auth_account")
        if not Ember.isEmpty(authToken) and not Ember.isEmpty(authAccountId)
            @authenticate authToken, authAccountId  

    isAuthenticated: () ->
        not Ember.isEmpty(@get("session.authToken")) and not Ember.isEmpty(@get("session.account"))

    authenticate: (authToken, accountId) ->
        account = App.Account.find(accountId)
        @set "session", App.Session.createRecord(
            authToken: authToken
            account: account
        )

    reset: () ->
        @set "session", null

    sessionObserver: () ->
        App.Store.authToken = @get("session.authToken")
        if Ember.isEmpty(@get("session"))
            $.removeCookie "auth_token"
            $.removeCookie "auth_account"
        else
            $.cookie "auth_token", @get("session.authToken")
            $.cookie "auth_account", @get("session.userId")
    ).observes("session")
)