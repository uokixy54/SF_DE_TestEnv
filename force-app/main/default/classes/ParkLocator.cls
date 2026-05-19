public class ParkLocator {
    public static List<String> country(String str) {
        parkService.ParksImplPort parks = new parkService.ParksImplPort();
        return parks.byCountry(str);
    }
}