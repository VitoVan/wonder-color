function wonder(text,url){
    $('.color-block').remove();
    $('#cssload-pgloading').show();
    $.post('/wonder',{text: text},function(data){
        var img = document.createElement('img');
        img.setAttribute('src',"/pics/" + data);
        img.addEventListener('load', function() {
            var vibrant = new Vibrant(img);
            var swatches = vibrant.swatches();
            var rendered = false;
            for (swatch in swatches)
                if (swatches.hasOwnProperty(swatch) && swatches[swatch]){
                    var invertColor = 'rgb(' + (255 - swatches[swatch].getRgb()[0]) + ','
                        + (255 - swatches[swatch].getRgb()[1]) + ',' + (255 - swatches[swatch].getRgb()[2]) + ')';
                    $('<div>')
                        .css('color',invertColor)
                        .text(swatches[swatch].getHex().toUpperCase())
                        .addClass('color-block')
                        .css('backgroundColor',swatches[swatch].getHex())
                        .insertAfter($('#colorname'));
                }
        });
        $('#cssload-pgloading').hide();
    });
}

$(document).ready(function(){
    $('#colorname').donetyping(function(){
        wonder($(this).val());
    });
    $('#colorname').val('new google logo');
    wonder($('#colorname').val());
});
