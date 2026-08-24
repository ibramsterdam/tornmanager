module KeyLogHelper
  TOOL_LABELS = {
    "tmanager" => "TornManager",
    "tmchats" => "TM Chats",
    "tmrecruiter" => "TM Recruiter"
  }.freeze

  def tool_label(comment)
    TOOL_LABELS[comment] || comment.presence || "No comment"
  end

  def tool_badge(comment)
    variant = TOOL_LABELS.key?(comment) ? comment : "other"
    tag.span(tool_label(comment), class: "tool-badge tool-badge--#{variant}", title: comment.presence || "no comment sent")
  end
end
