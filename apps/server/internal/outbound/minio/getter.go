package minio

import "time"

func (s *MinIOStorage) UploadExp() time.Duration {
	return s.cfg.UploadExp
}

func (s *MinIOStorage) DownloadExp() time.Duration {
	return s.cfg.DownloadExp
}
