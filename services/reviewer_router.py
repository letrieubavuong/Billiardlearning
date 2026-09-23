import os
import json
from google import genai
from google.genai import types

def review_commit_bundle(commit_diff, contract_text):
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("GEMINI_API_KEY environment variable is missing.")
        
    client = genai.Client(api_key=api_key)
    model_name = os.environ.get("GEMINI_REVIEW_MODEL", "gemini-2.5-flash")

    system_instruction = \"\"\"
    You are an independent technical reviewer.
    Review only according to the provided PHASE_ACCEPTANCE_CONTRACT.
    DO NOT EXPAND SCOPE. DO NOT ADD NEW ACCEPTANCE GATES.
    Return NEEDS_FIX only for blocking defects inside frozen scope:
    - correctness, security, data loss, state machine invariant, 
    - frozen gate failure, protected path violation, required test failure.
    
    You MUST respond in strict JSON format matching this schema:
    {
      "verdict": "PASS | PASS_WITH_NOTES | NEEDS_FIX | BLOCKED",
      "reviewed_commit_sha": "...",
      "blocking_findings": [],
      "non_blocking_findings": [],
      "contract_gate_results": [{"gate": "...", "status": "PASS | FAIL", "evidence": "..."}],
      "scope_expansion_attempted": false,
      "summary": "..."
    }
    \"\"\"

    prompt = f\"\"\"
    === PHASE ACCEPTANCE CONTRACT ===
    {contract_text}

    === EXACT COMMIT DIFF ===
    {commit_diff}
    \"\"\"

    response = client.models.generate_content(
        model=model_name,
        contents=prompt,
        config=types.GenerateContentConfig(
            system_instruction=system_instruction,
            response_mime_type="application/json",
            temperature=0.1,
        ),
    )
    
    return response.text

if __name__ == "__main__":
    print("Reviewer Router module loaded successfully with Google AI Studio.")
