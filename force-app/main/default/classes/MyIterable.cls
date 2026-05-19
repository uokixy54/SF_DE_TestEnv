public class MyIterable implements Iterable<String>{
	private List<string> strings;
    
    public MyIterable(List<String> strings){
        this.strings = strings;
    }
    
    public Iterator<String> iterator(){
        return strings.iterator();
    }  
}