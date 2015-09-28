function wonder(text,url){
    $.post('/wonder',{text: text},function(data){
        console.log("/pics/" + data);
        var img = document.createElement('img');
        img.setAttribute('src',"/pics/" + data);
        img.addEventListener('load', function() {
            var vibrant = new Vibrant(img);
            var swatches = vibrant.swatches();
            var rendered = false;
            $('.color-block').remove();
            for (swatch in swatches)
                if (swatches.hasOwnProperty(swatch) && swatches[swatch]){
                    console.log(swatch, swatches[swatch].getHex());
                    $('<div>')
                        .addClass('color-block')
                        .css('backgroundColor',swatches[swatch].getHex())
                        .insertAfter($('#colorname'));
                }
        });
    });
}

$(document).ready(function(){
    $('#colorname').donetyping(function(){
        wonder($(this).val());
    });
    $('#colorname').val('I feel sorrow');
    wonder($('#colorname').val());
});
