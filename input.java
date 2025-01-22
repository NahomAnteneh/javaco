public class QueryExecutor {
    public void execute() {
        int firstToken = tokens.get(0);
        switch (firstToken.getType()) {
            case SELECT:
                // tokens.remove(0);
                executeSelect();
                break;
            case INSERT:
                // tokens.remove(0);
                executeInsert();
                break;
            case DELETE:
                // tokens.remove(0);
                executeDelete();
                break;
            default:
                IllegalArgumentException("Unsupported query type: ");
        }
    }

    private void executeInsert() {
        
    }

    private void executeDelete() {
        
    }
}