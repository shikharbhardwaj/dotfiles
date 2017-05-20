exec sensors | grep "temp1"  | awk '/temp1/{i++}i==3' | awk -v FS="(+|C)" '{print $2}'
