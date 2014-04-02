/**
 * This class is automatically generated by mig. DO NOT EDIT THIS FILE.
 * This class implements a Java interface to the 'AutoConfigMsg'
 * message type.
 */

public class AutoConfigMsg extends net.tinyos.message.Message {

    /** The default size of this message type in bytes. */
    public static final int DEFAULT_MESSAGE_SIZE = 2;

    /** The Active Message type associated with this message. */
    public static final int AM_TYPE = 1;

    /** Create a new AutoConfigMsg of size 2. */
    public AutoConfigMsg() {
        super(DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /** Create a new AutoConfigMsg of the given data_length. */
    public AutoConfigMsg(int data_length) {
        super(data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new AutoConfigMsg with the given data_length
     * and base offset.
     */
    public AutoConfigMsg(int data_length, int base_offset) {
        super(data_length, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new AutoConfigMsg using the given byte array
     * as backing store.
     */
    public AutoConfigMsg(byte[] data) {
        super(data);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new AutoConfigMsg using the given byte array
     * as backing store, with the given base offset.
     */
    public AutoConfigMsg(byte[] data, int base_offset) {
        super(data, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new AutoConfigMsg using the given byte array
     * as backing store, with the given base offset and data length.
     */
    public AutoConfigMsg(byte[] data, int base_offset, int data_length) {
        super(data, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new AutoConfigMsg embedded in the given message
     * at the given base offset.
     */
    public AutoConfigMsg(net.tinyos.message.Message msg, int base_offset) {
        super(msg, base_offset, DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new AutoConfigMsg embedded in the given message
     * at the given base offset and length.
     */
    public AutoConfigMsg(net.tinyos.message.Message msg, int base_offset, int data_length) {
        super(msg, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
    /* Return a String representation of this message. Includes the
     * message type name and the non-indexed field values.
     */
    public String toString() {
      String s = "Message <AutoConfigMsg> \n";
      try {
        s += "  [srcRank=0x"+Long.toHexString(get_srcRank())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [dstRank=0x"+Long.toHexString(get_dstRank())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      return s;
    }

    // Message-type-specific access methods appear below.

    /////////////////////////////////////////////////////////
    // Accessor methods for field: srcRank
    //   Field type: short, unsigned
    //   Offset (bits): 0
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'srcRank' is signed (false).
     */
    public static boolean isSigned_srcRank() {
        return false;
    }

    /**
     * Return whether the field 'srcRank' is an array (false).
     */
    public static boolean isArray_srcRank() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'srcRank'
     */
    public static int offset_srcRank() {
        return (0 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'srcRank'
     */
    public static int offsetBits_srcRank() {
        return 0;
    }

    /**
     * Return the value (as a short) of the field 'srcRank'
     */
    public short get_srcRank() {
        return (short)getUIntBEElement(offsetBits_srcRank(), 8);
    }

    /**
     * Set the value of the field 'srcRank'
     */
    public void set_srcRank(short value) {
        setUIntBEElement(offsetBits_srcRank(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'srcRank'
     */
    public static int size_srcRank() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'srcRank'
     */
    public static int sizeBits_srcRank() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: dstRank
    //   Field type: short, unsigned
    //   Offset (bits): 8
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'dstRank' is signed (false).
     */
    public static boolean isSigned_dstRank() {
        return false;
    }

    /**
     * Return whether the field 'dstRank' is an array (false).
     */
    public static boolean isArray_dstRank() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'dstRank'
     */
    public static int offset_dstRank() {
        return (8 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'dstRank'
     */
    public static int offsetBits_dstRank() {
        return 8;
    }

    /**
     * Return the value (as a short) of the field 'dstRank'
     */
    public short get_dstRank() {
        return (short)getUIntBEElement(offsetBits_dstRank(), 8);
    }

    /**
     * Set the value of the field 'dstRank'
     */
    public void set_dstRank(short value) {
        setUIntBEElement(offsetBits_dstRank(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'dstRank'
     */
    public static int size_dstRank() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'dstRank'
     */
    public static int sizeBits_dstRank() {
        return 8;
    }

}
