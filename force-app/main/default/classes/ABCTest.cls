@isTest
private class ABCTest {

    @isTest
    static void shouldCreateInstance_WhenConstructorCalled() {
        // When
        Test.startTest();
        ABC instance = new ABC();
        Test.stopTest();

        // Then
        Assert.isNotNull(instance, 'ABC constructor should return a non-null instance');
        Assert.isInstanceOfType(instance, ABC.class, 'Instance should be of type ABC');
    }
}
