package request

import "github.com/Ascension-EIP/Ascension/apps/server/internal/model"

type PaginationQuery struct {
	Offset int `form:"offset,default=0" binding:"min=0"`
	Limit  int `form:"limit,default=10" binding:"min=1,max=20"`
}

func (q PaginationQuery) IntoPagination() model.Pagination {
	return model.Pagination{
		Offset: q.Offset,
		Limit:  q.Limit,
	}
}

// HOW TO USE ^
// var query request.PaginationQuery
// if err := c.ShouldBindQuery(&query); err != nil {
// 	c.JSON(http.StatusBadRequest, response.NewError(err))
// 	return
// }
