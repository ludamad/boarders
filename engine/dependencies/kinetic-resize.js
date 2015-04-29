KineticScreenAutoSize = (function() {
  var self = {
    $container: null,
    stage: null,
    baseWidth: 0,
    baseHeight: 0,
    initWidth: 0,
    initHeight: 0
  };

  /*
   * Screen-Sizing Methods
   */
  var autoSize = function() {  
    // Style required for resizeScreen below
    self.$container.css({
      position: 'absolute',
      left: '50%',
      top: '50%',
      width: '100%',
      height: '100%'
    });

    // Resize automatically
    window.addEventListener('resize', resizeStageToFitScreen, false);
    window.addEventListener('orientationchange', resizeStageToFitScreen, false);

    // Resize
    resized = resizeStageToFitScreen();
  };

  var init = function(stage, selector) {
    self.$container = $(selector);
    self.baseWidth = stage.width();
    self.baseHeight = stage.height();
    self.stage = stage;
    autoSize();
  };

  var resizeStageToFitScreen = function() {
    /*
     * Following directions here: http://stackoverflow.com/a/19645405/1093087
     */
    var resized = calculateResize();

    // Resize the kinetic container element proportionally
    resized.cssSettings = {
      left: resized.xToCenter + 'px',
      top: resized.yToCenter + 'px',
      width: resized.width,
      height: resized.height,
    }
    self.$container.css(resized.cssSettings);

    // Let Kinetic know its container is resizing with .setWidth and .setHeight
    self.stage.setSize(resized);

    // Use .setScaleX and setScaleY followed by stage.draw to scale the stage
    // and all its components.
    self.stage.scaleX(resized.xScale);
    self.stage.scaleY(resized.yScale);

    self.stage.draw();
    return resized;
  };

  var calculateResize = function() {
    var resized = {
      width: 0,
      height: 0,
      xScale: 0,
      yScale: 0,
      xToCenter: 0,
      yToCenter: 0
    }

    var windowWidth = window.innerWidth,
        windowHeight = window.innerHeight,
        desiredWidthToHeightRatio = self.baseWidth / self.baseHeight,
        currentWidthToHeightRatio = windowWidth / windowHeight;

    if ( currentWidthToHeightRatio > desiredWidthToHeightRatio ) {
      resized.width = windowHeight * desiredWidthToHeightRatio;
      resized.height = windowHeight;
    }
    else {
      resized.width = windowWidth;
      resized.height = windowWidth / desiredWidthToHeightRatio;
    }

    resized.xToCenter = (window.innerWidth - resized.width) / 2;
    resized.yToCenter = (window.innerHeight - resized.height) / 2;
    resized.xScale = resized.width/self.baseWidth,
    resized.yScale = resized.height/self.baseHeight;

    return resized;
  };

  /*
   * Public API
   */
  var publicAPI = {
    init: init,
    stage: function() { return self.stage },
    autoSize: autoSize
  }

  return publicAPI;

})();