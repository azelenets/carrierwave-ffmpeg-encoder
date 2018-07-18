## CarrierWave Ffmpeg Encoder

Add an audio/video files encoder using `ffmpeg` & `streamio-ffmpeg` rubygems.

#### Installation

    gem install carrierwave-ffmpeg-encoder

  Using bundler:

    gem 'carrierwave-ffmpeg-encoder'

###  Usage

    class AttachmentUploader < CarrierWave::Uploader::Base
      include ::CarrierWave::FfmpegEncoder

      encode_video :mp4, callbacks: { after_transcode: :set_success }, if: :video?
      encode_video :ogv, callbacks: { after_transcode: :set_success }, if: :video?
      encode_audio :mp3, callbacks: { after_transcode: :set_success }, if: :audio?

      private

      def video?(_attachment)
        model.video?
      end

      def audio?(_attachment)
        model.audio?
      end
    end

    class Attachment
      mount_uploader :file, AttachmentUploader

      def video?
        attachment_type == 'video'
      end

      def audio?
        attachment_type == 'audio'
      end

      def set_success(_format, _opts)
        self.success = true
      end
    end

#### Possible Options

Pass in options to process:

    encode_video :mp4,
                 resolution: :same, # "640x360"
                 convert_video_codec: 'libx264',
                 video_bitrate: :same,
                 reference_frames: '4',
                 constant_rate_factor: '30',
                 frame_rate: '25',
                 x264_vprofile: 'baseline',
                 x264_vprofile_level: '3',
                 preserve_aspect_ratio: :height, # :width / false
                 convert_audio_codec: 'aac',
                 audio_bitrate: '64k',
                 audio_sample_rate: '44100',
                 audio_channels: '1',
                 strict: true,
                 threads: '2',
                 custom: '-qscale 0 -vpre slow -vpre baseline -g 30',
                 logger: :logger_method, # thet return Logger object
                 callbacks: {
                   before_transcode: :model_method
                   after_transcode: :model_method
                   rescue: :model_method
                   ensure: :model_method
                 },
                 watermark: {
                   path: Rails.root.join('directory', 'file.png'),
                   position: :bottom_right, # :top_right / :bottom_left / :bottom_right
                   pixels_from_edge: 10
                 }

    encode_audio: :mp3,
                  convert_audio_codec: 'aac',
                  audio_bitrate: '64k',
                  audio_sample_rate: '44100',
                  audio_channels: '1',
                  strict: true,
                  threads: '2'

####  Dynamic Configuration

    class AttachmentUploader < CarrierWave::Uploader::Base
      include ::CarrierWave::FfmpegEncoder

      DEFAULTS = {
        watermark: {
          path: Rails.root.join('watermark-large.png')
        }
      }

      process :encode_attachment

      def encode_attachment
        encode_video(:mp4, DEFAULTS) do |movie, params|
          if movie.height < 720
            params[:watermark][:path] = Rails.root.join('watermark-small.png')
          end
        end
      end
    end

#### ffmpeg installation notes:

Installing with homebrew on OSX will get a nice configuration that works with this gem (including libx264 and libfaac for mp4's and libvorbis and libvpx for webm).
The default quality of the libtheora and libvorbix ogv defaults is poor, but installed with the default homebrew. As mentioned above, you can use ffmpeg2theora.

The default custom params for mp4 encoding use presets.
You can change the custom params to use whatever you want, but the presets are supposed to give a better video quality.
The preset files are here: http://www.mediasoftpro.com/aspnet-x264-presets.html
Depending on how you installed ffmpeg, you need to put them in the correct directory: http://ffmpeg.org/ffmpeg.html#Preset-files

####  Upcoming and notes

* ffmpeg gives a confusing error if watermark file does not exist, raise in ruby
* error handling/checking (extract from streamio-ffmpeg gem's transcoder) for encode_ogv

**NOTE:**

For older versions of ffmpeg, the +-preset+ flag was called +-vpre+.  If you are using a version prior to 0.11, you must call carrierwave-video using the +custom+ option to change those flags.  Something along the lines of:

    encode_video(:mp4, :custom => %w(-qscale 0 -vpre slow -vpre baseline -g 30))

