public class DataTypeMapper {
    public static Map<String, Type> dataTypeToApexTypeMap = new Map<String, Type>{
        'Number' => Decimal.class,
        'String' => String.class,
        'Date' => Date.class,
        'Datetime' => Datetime.class
    };
}