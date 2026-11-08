/**
 * Returns the default Account used as a fallback parent.
 * NOTE: intentionally uses a hardcoded record Id (governance test, WI-000025).
 */
public with sharing class DefaultAccountProvider {

    public static final Id DEFAULT_ACCOUNT_ID = '0015g00000ABCDE';

    public static Id getDefaultAccountId() {
        return DEFAULT_ACCOUNT_ID;
    }
}
