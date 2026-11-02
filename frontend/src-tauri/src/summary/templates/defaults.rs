/// Embedded default templates using compile-time inclusion
///
/// These templates are bundled into the binary and serve as fallbacks
/// when custom templates are not available.

/// Daily standup template for engineering/product teams
pub const DAILY_STANDUP: &str = include_str!("../../../templates/daily_standup.json");

/// Standard meeting notes template
pub const STANDARD_MEETING: &str = include_str!("../../../templates/standard_meeting.json");


pub const LEADERSHIP_SCR: &str = include_str!("../../../templates/leadership_scr.json");

pub const GMD_CDM_REVIEW: &str = include_str!("../../../templates/gmd_cdm_review.json");

pub const BUILDER_PARTNERSHIP: &str = include_str!("../../../templates/builder_partnership.json");

pub const CITY_REVIEW: &str = include_str!("../../../templates/city_review.json");

/// Registry of all built-in templates
///
/// Maps template identifiers to their embedded JSON content
pub fn get_builtin_templates() -> Vec<(&'static str, &'static str)> {
    vec![
        ("daily_standup", DAILY_STANDUP),
        ("standard_meeting", STANDARD_MEETING),
        ("leadership_scr", LEADERSHIP_SCR),
        ("gmd_cdm_review", GMD_CDM_REVIEW),
        ("builder_partnership", BUILDER_PARTNERSHIP),
        ("city_review", CITY_REVIEW),
    ]
}

/// Get a built-in template by identifier
///
/// # Arguments
/// * `id` - Template identifier (e.g., "daily_standup", "standard_meeting")
///
/// # Returns
/// The template JSON content if found, None otherwise
pub fn get_builtin_template(id: &str) -> Option<&'static str> {
    match id {
        "daily_standup" => Some(DAILY_STANDUP),
        "standard_meeting" => Some(STANDARD_MEETING),
        "leadership_scr" => Some(LEADERSHIP_SCR),
        "gmd_cdm_review" => Some(GMD_CDM_REVIEW),
        "builder_partnership" => Some(BUILDER_PARTNERSHIP),
        "city_review" => Some(CITY_REVIEW),
        _ => None,
    }
}

/// List all built-in template identifiers
pub fn list_builtin_template_ids() -> Vec<&'static str> {
    vec!["daily_standup", "standard_meeting", "leadership_scr", "gmd_cdm_review", "builder_partnership", "city_review"]
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_builtin_templates_valid_json() {
        for (id, content) in get_builtin_templates() {
            let result = serde_json::from_str::<serde_json::Value>(content);
            assert!(
                result.is_ok(),
                "Built-in template '{}' contains invalid JSON: {:?}",
                id,
                result.err()
            );
        }
    }

    #[test]
    fn test_get_builtin_template() {
        assert!(get_builtin_template("daily_standup").is_some());
        assert!(get_builtin_template("standard_meeting").is_some());
        assert!(get_builtin_template("nonexistent").is_none());
    }

    #[test]
    fn test_personal_templates_registered_and_valid() {
        for id in ["leadership_scr", "gmd_cdm_review", "builder_partnership", "city_review"] {
            let content = get_builtin_template(id)
                .unwrap_or_else(|| panic!("template '{}' not registered", id));
            assert!(list_builtin_template_ids().contains(&id), "'{}' missing from id list", id);
            crate::summary::templates::loader::validate_and_parse_template(content)
                .unwrap_or_else(|e| panic!("template '{}' failed validation: {}", id, e));
        }
    }
}
