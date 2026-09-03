// @date 2026-03-18
// @file getter.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package minio

import "time"

func (s *MinIOStorage) UploadExp() time.Duration {
	return s.cfg.UploadExp
}

func (s *MinIOStorage) DownloadExp() time.Duration {
	return s.cfg.DownloadExp
}

func (s *MinIOStorage) VideoBucket() string {
	return s.cfg.BucketName
}
