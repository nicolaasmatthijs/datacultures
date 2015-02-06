/**
 * TODO
 */
(function(angular) {
  'use strict';

  angular.module('datacultures.config').config(function($analyticsProvider) {
    // turn off automatic tracking
    $analyticsProvider.virtualPageviews(false);
  });
})(window.angular);
