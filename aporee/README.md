```
ia search 'collection:radio-aporee-maps AND birds' --itemlist >> todownload.txt
ia search 'collection:radio-aporee-maps AND ocean' --itemlist >> todownload.txt
ia search 'collection:radio-aporee-maps AND forest' --itemlist >> todownload.txt
mv todownload.txt 1
cat 1 | sort | uniq > todownload.txt

while read item; do
    echo "Processing: $item"
    ia download "$item" --destdir=download_output --glob="*.ogg"
done < todownload.txt
while read item; do
    echo "Processing: $item"
    ia download "$item" --destdir=download_output --glob="*.xml"
done < todownload.txt
```
