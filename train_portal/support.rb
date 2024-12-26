module TrainPortal
  module Support
    module_function

    def progress_bar(title, total)
      ProgressBar.create(format: "%a %b\e[93m\u{15E7}\e[0m%i %p%% #{title}",
        progress_mark: ' ',
        remainder_mark: "\u{FF65}",
        total: total)
    end
  end
end
