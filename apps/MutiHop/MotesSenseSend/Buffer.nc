interface Buffer<t> {
    /**
     * Get data from the buffer. The data will be removed from the buffer.
     *
     * @param dst - The destination array to store data from the buffer.
     * @param off - The position in destination array to start to store data from.
     * @param len - The size of data expected.
     * @return The size of data got from the buffer.
     */
    command uint16_t get(t* dst, uint16_t off, uint16_t len);

    /**
     * Put data into the buffer.
     *
     * @param src - The array of data to be stored into the buffer.
     * @param off - The offset of data in the buf array.
     * @param len - The length of data in the buf array.
     * @return The size of data put into the buffer.
     */
    command uint16_t put(t* src, uint16_t off, uint16_t len);

    /**
     * The size of data stored in the buffer.
     *
     * @return The size of data.
     */
    command uint16_t size();

    /**
     * The max size of buffer.
     *
     * @return The max size of buffer.
     */
    command uint16_t maxSize();

    /**
     * Returns if the buffer is empty.
     *
     * @return Whether the buffer is empty.
     */
    command bool empty();

    /**
     * Find the index of a.
     *
     * @param a - The single element to be searched in the buffer.
     * @param aidx - The offset of a if a is found in the buffer.
     * @return If a exists in the buffer.
     */
    command bool find(t a, uint16_t* aidx);

    /**
     * Clear all the buffer.
     */
    command void clearAll();

    /**
     * Clear specified size of data in the buffer.
     *
     * @param len - The size of data to be cleared.
     */
    command void clear(uint16_t len);

    /**
     * Get the data element at idx.
     *
     * @param idx - The index of the data to be retrieved.
     * @return The data.
     */
    command t dataAt(uint16_t idx);
}
