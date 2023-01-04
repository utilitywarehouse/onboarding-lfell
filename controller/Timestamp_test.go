package controller

import (
	"github.com/stretchr/testify/assert"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/labstack/echo/v4"
)

// Assert a 200 is returned from GetTimestamp
func TestTimestampController_GetTimestamp(t *testing.T) {
	// Begin echo set up
	request, _ := http.NewRequest(http.MethodGet, "timestamp", nil)
	request.Header.Set("Content-Type", "application/json")

	recorder := httptest.NewRecorder()

	context := echo.New().NewContext(request, recorder)
	context.Reset(request, recorder)

	// Begin controller set up
	timestampController := NewTimestampController()

	// Begin assertions
	assert.NoError(t, timestampController.GetTimestamp(context))
	assert.Equal(t, http.StatusOK, context.Response().Status)
}
