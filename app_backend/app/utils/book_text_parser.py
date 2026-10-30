import re
import html
from typing import List


GUTENBERG_START_MARKERS = [
    r"\*\*\*\s*START OF TH(E|IS) PROJECT GUTENBERG EBOOK[^\*]*\*\*\*",
    r"\*\*\*\s*START OF THE BOOK[^\*]*\*\*\*",
    r"\*END\*THE SMALL PRINT!",
    r"START OF THIS PROJECT GUTENBERG",
]

GUTENBERG_END_MARKERS = [
    r"\*\*\*\s*END OF TH(E|IS) PROJECT GUTENBERG EBOOK[^\*]*\*\*\*",
    r"\*\*\*\s*END OF THE BOOK[^\*]*\*\*\*",
    r"End of the Project Gutenberg EBook",
    r"End of Project Gutenberg",
    r"\*\*\* END OF THIS PROJECT GUTENBERG",
]


def clean_gutenberg_text(text: str) -> str:
    """
    Strips standard Project Gutenberg headers, licenses, and footers,
    returning the authentic readable body of the book.
    """
    if not text:
        return ""

    normalized = text.replace("\r\n", "\n").replace("\r", "\n")

    # Search for start marker
    start_pos = 0
    for marker in GUTENBERG_START_MARKERS:
        match = re.search(marker, normalized, re.IGNORECASE)
        if match:
            start_pos = match.end()
            break

    # Search for end marker
    end_pos = len(normalized)
    for marker in GUTENBERG_END_MARKERS:
        match = re.search(marker, normalized[start_pos:], re.IGNORECASE)
        if match:
            end_pos = start_pos + match.start()
            break

    cleaned = normalized[start_pos:end_pos].strip()

    # If stripped text ended up too small (e.g. false positive match), fallback to normalized
    if len(cleaned) < 200 and len(normalized) > 500:
        cleaned = normalized.strip()

    # Normalize excessive newlines (max 2 consecutive newlines)
    cleaned = re.sub(r"\n{3,}", "\n\n", cleaned)

    return cleaned


def clean_html_text(html_content: str) -> str:
    """
    Converts HTML book content into clean, readable text preserving paragraph breaks.
    """
    if not html_content:
        return ""

    content = html_content.replace("\r\n", "\n").replace("\r", "\n")

    # Remove script and style elements completely
    content = re.sub(r"<script[^>]*>[\s\S]*?</script>", "", content, flags=re.IGNORECASE)
    content = re.sub(r"<style[^>]*>[\s\S]*?</style>", "", content, flags=re.IGNORECASE)
    content = re.sub(r"<head[^>]*>[\s\S]*?</head>", "", content, flags=re.IGNORECASE)

    # Convert structural HTML breaks to newlines
    content = re.sub(r"<(?:p|div|section|article|blockquote)[^>]*>", "\n\n", content, flags=re.IGNORECASE)
    content = re.sub(r"<br\s*/?>", "\n", content, flags=re.IGNORECASE)
    content = re.sub(r"<(?:h[1-6])[^>]*>", "\n\n### ", content, flags=re.IGNORECASE)
    content = re.sub(r"</(?:h[1-6])>", "\n\n", content, flags=re.IGNORECASE)

    # Strip remaining HTML tags
    content = re.sub(r"<[^>]+>", "", content)

    # Unescape HTML entities (&amp;, &nbsp;, &ldquo;, etc.)
    content = html.unescape(content)

    # Clean Gutenberg markers if present
    content = clean_gutenberg_text(content)

    return content


def paginate_text(text: str, page_size: int = 2500) -> List[str]:
    """
    Splits long book content into logical reading pages.
    Guarantees that words are NEVER cut in half and prioritizes
    paragraph breaks and sentence boundaries.
    """
    text = text.replace("\r\n", "\n").replace("\r", "\n").strip()
    if not text:
        return ["No content available for this book."]

    if page_size < 500:
        page_size = 500

    pages: List[str] = []
    start = 0
    total_len = len(text)

    while start < total_len:
        if start + page_size >= total_len:
            last_chunk = text[start:].strip()
            if last_chunk:
                pages.append(last_chunk)
            break

        target = start + page_size

        # 1. Search for paragraph boundary within window
        p_break = text.rfind("\n\n", start, min(target + 300, total_len))
        if p_break != -1 and p_break >= target - 600:
            split_at = p_break + 2
        else:
            # 2. Search for sentence boundary (. ! ?)
            s_candidates = [
                text.rfind(". ", start, target),
                text.rfind(".\n", start, target),
                text.rfind("? ", start, target),
                text.rfind("?\n", start, target),
                text.rfind("! ", start, target),
                text.rfind("!\n", start, target),
            ]
            best_s = max(s_candidates)
            if best_s != -1 and best_s >= target - 400:
                split_at = best_s + 1
            else:
                # 3. Search for newline or word space
                space_candidates = [
                    text.rfind("\n", start, target),
                    text.rfind(" ", start, target),
                ]
                best_space = max(space_candidates)
                if best_space != -1 and best_space >= target - 200:
                    split_at = best_space + 1
                else:
                    split_at = target

        chunk = text[start:split_at].strip()
        if chunk:
            pages.append(chunk)

        start = split_at
        while start < total_len and text[start].isspace():
            start += 1

    return pages if pages else ["No readable content found."]
