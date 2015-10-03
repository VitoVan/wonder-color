function hexToRgb(hex) {
    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
    } : null;
}
function wonder(text){
    $('.color-block').remove();
    $('#cssload-pgloading').show();
    $.post('/wonder-api',{text: text},function(data){
        for (index in data){
            var rgbColor = hexToRgb(data[index]);
            var invertColor = 'rgb(' + (255 - rgbColor.r) + ','
                + (255 - rgbColor.g) + ',' + (255 - rgbColor.b) + ')';
            $('<div>')
                .css('color',invertColor)
                .text(data[index])
                .addClass('color-block')
                .css('backgroundColor', data[index])
                .insertAfter($('#colorname'));
        }
        $('#cssload-pgloading').hide();
    });
}

$(document).ready(function(){
    $('#colorname').donetyping(function(){
        wonder($(this).val());
    });
    $('#colorname').val('hello kitty');
    wonder($('#colorname').val());
});
