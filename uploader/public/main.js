$(function(){
  $(".file").on('click',function(){
    if(confirm('Really remove?')){
      elem = $(this)
      name = elem.data('name')
      $.post("/remove",{name:name})
      .success(function(){
        elem.remove()
      });
    }
  });
});
