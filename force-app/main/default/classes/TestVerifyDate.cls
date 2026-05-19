@isTest
private class TestVerifyDate {
    @isTest
    static void testCheckDates1() {
        Date date1 = Date.newInstance(2024, 1, 1);
        Date date2 = Date.newInstance(2023, 12, 31);
        Date result;

        result = VerifyDate.CheckDates(date1, date2);

        System.debug('result1: ' + result);
        System.assertEquals(Date.newInstance(2024, 1, 31), result, 'ERROR');
    }

    @isTest
    static void testCheckDates2() {
        Date date1 = Date.newInstance(2024, 1, 1);
        Date date2 = Date.newInstance(2024, 1, 2);
        Date result;

        result = VerifyDate.CheckDates(date1, date2);

        System.debug('result2: ' + result);
        System.assertEquals(Date.newInstance(2024, 1, 2), result, 'ERROR');
    }

    @isTest
    static void testCheckDates3() {
        Date date1 = Date.newInstance(2024, 1, 1);
        Date date2 = Date.newInstance(2024, 5, 1);
        Date result;

        result = VerifyDate.CheckDates(date1, date2);

        System.debug('result3: ' + result);
        System.assertEquals(Date.newInstance(2024, 1, 31), result, 'ERROR');
    }
}