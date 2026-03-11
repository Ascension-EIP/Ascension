package postgres

// func (r *Repo) CreateSession(ctx context.Context, session *entity.Session) error {
// 	if session == nil {
// 		return ErrModelNil
// 	}
// 	m := model.SessionFromEntity(session)
// 	if err := r.db.WithContext(ctx).Create(m).Error; err != nil {
// 		switch {
// 		case errors.Is(err, gorm.ErrDuplicatedKey):
// 			return ErrDuplicatedKey
// 		case errors.Is(err, gorm.ErrForeignKeyViolated):
// 			return ErrForeignKeyViolated
// 		default:
// 			return err
// 		}
// 	}
// 	session.CreatedAt = m.CreatedAt
// 	session.UpdatedAt = m.UpdatedAt
// 	return nil
// }
//
// func (r *Repo) GetSession(ctx context.Context, id string) (*entity.Session, error) {
// 	var session model.Session
// 	if err := r.db.WithContext(ctx).
// 		Where("id = ?", id).
// 		First(&session).
// 		Error; err != nil {
// 		switch {
// 		case errors.Is(err, gorm.ErrRecordNotFound):
// 			return nil, ErrNotFound
// 		default:
// 			return nil, err
// 		}
// 	}
// 	return model.SessionToEntity(&session), nil
// }
//
// func (r *Repo) GetUnexpiredSession(ctx context.Context, id string) (*entity.Session, error) {
// 	var session model.Session
// 	if err := r.db.WithContext(ctx).
// 		Where("id = ? AND expires_at > ?", id, time.Now()).
// 		First(&session).
// 		Error; err != nil {
// 		switch {
// 		case errors.Is(err, gorm.ErrRecordNotFound):
// 			return nil, ErrNotFound
// 		default:
// 			return nil, err
// 		}
// 	}
// 	return model.SessionToEntity(&session), nil
// }
//
// func (r *Repo) UpdateSession(ctx context.Context, session *entity.Session) error {
// 	if session == nil {
// 		return ErrModelNil
// 	}
// 	m := model.SessionFromEntity(session)
// 	if err := r.db.WithContext(ctx).
// 		Where("id = ?", session.ID).
// 		Updates(m).
// 		Error; err != nil {
// 		switch {
// 		case errors.Is(err, gorm.ErrRecordNotFound):
// 			return ErrNotFound
// 		case errors.Is(err, gorm.ErrForeignKeyViolated):
// 			return ErrDuplicatedKey
// 		default:
// 			return err
// 		}
// 	}
// 	return nil
// }
//
// func (r *Repo) DeleteSession(ctx context.Context, id string) error {
// 	if err := r.db.WithContext(ctx).
// 		Where("id = ?", id).
// 		Delete(&model.Session{}).
// 		Error; err != nil {
// 		switch {
// 		case errors.Is(err, gorm.ErrRecordNotFound):
// 			return ErrNotFound
// 		default:
// 			return err
// 		}
// 	}
// 	return nil
// }
//
// func (r *Repo) DeleteSessionByUserID(ctx context.Context, userID uint, id string) error {
// 	if err := r.db.WithContext(ctx).
// 		Where("id = ? AND user_id = ?", id).
// 		Delete(&model.Session{}).
// 		Error; err != nil {
// 		switch {
// 		case errors.Is(err, gorm.ErrRecordNotFound):
// 			return ErrNotFound
// 		default:
// 			return err
// 		}
// 	}
// 	return nil
// }
//
// func (r *Repo) DeleteExpiredSessions(ctx context.Context) error {
// 	if err := r.db.WithContext(ctx).Where("expires_at < ?", time.Now()).Delete(&model.Session{}).Error; err != nil {
// 		return err
// 	}
// 	return nil
// }
