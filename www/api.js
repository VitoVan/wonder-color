function doVibrant(){
    var img = document.getElementsByTagName('img')[0];
    var vibrant = new Vibrant(img);
    var swatches = vibrant.swatches();
    var resultStr = '( ';
    for (swatch in swatches){
        if (swatches.hasOwnProperty(swatch) && swatches[swatch]){
            resultStr += ('"' + swatches[swatch].getHex() + '"' + ' ');
        }
    }
    resultStr += ')'
    console.log(resultStr);
    console.log('PHANTOM:EXIT');
}
