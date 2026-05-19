@isTest
private class AnimalLocatorTest {
    @isTest
    static void testGetCallout() {
        Test.setMock(HttpCalloutMock.class, new AnimalLocatorMock());

        String response = AnimalLocator.getAnimalNameById(1);

        Assert.areEqual(response, 'chicken');
    }
}