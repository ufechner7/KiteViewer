# import log_8700W_8ms.csv.xz
#
# Step 1: decompress the file to a csv file - DONE -
# Step 2: read the csv file
# Step 3: write an arrow file

using CodecXz

const FILENAME="data/log_8700W_8ms.csv.xz"

stream = open(FILENAME)
output = open(FILENAME[1:end-3],"w")
for line in eachline(XzDecompressorStream(stream))
    println(output, line)
end
close(stream)
close(output)