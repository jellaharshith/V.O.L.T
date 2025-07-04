/*
  # Contract Chunks Table for RAG System

  1. New Tables
    - `contract_chunks`
      - `id` (uuid, primary key)
      - `doc_name` (text)
      - `chunk_text` (text)
      - `chunk_index` (integer)
      - `doc_type` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on `contract_chunks` table
    - Add policy for authenticated users to read chunks

  3. Sample Data
    - Insert example chunks for general, lease, and employment contracts
*/

-- Create contract_chunks table if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'contract_chunks') THEN
    CREATE TABLE public.contract_chunks (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      doc_name text NOT NULL,
      chunk_text text NOT NULL,
      chunk_index integer NOT NULL DEFAULT 0,
      doc_type text NOT NULL DEFAULT 'general',
      created_at timestamptz DEFAULT now(),
      updated_at timestamptz DEFAULT now()
    );
  END IF;
END $$;

-- Add missing columns if they don't exist
DO $$
BEGIN
  -- Add doc_type column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'contract_chunks' AND column_name = 'doc_type'
  ) THEN
    ALTER TABLE public.contract_chunks ADD COLUMN doc_type text NOT NULL DEFAULT 'general';
  END IF;

  -- Add chunk_index column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'contract_chunks' AND column_name = 'chunk_index'
  ) THEN
    ALTER TABLE public.contract_chunks ADD COLUMN chunk_index integer NOT NULL DEFAULT 0;
  END IF;

  -- Add created_at column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'contract_chunks' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE public.contract_chunks ADD COLUMN created_at timestamptz DEFAULT now();
  END IF;

  -- Add updated_at column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'contract_chunks' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE public.contract_chunks ADD COLUMN updated_at timestamptz DEFAULT now();
  END IF;
END $$;

-- Enable RLS
ALTER TABLE public.contract_chunks ENABLE ROW LEVEL SECURITY;

-- Create policy if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'contract_chunks' AND policyname = 'Authenticated users can read contract chunks'
  ) THEN
    CREATE POLICY "Authenticated users can read contract chunks"
      ON public.contract_chunks
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END $$;

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS contract_chunks_doc_name_idx ON public.contract_chunks(doc_name);
CREATE INDEX IF NOT EXISTS contract_chunks_doc_type_idx ON public.contract_chunks(doc_type);
CREATE INDEX IF NOT EXISTS contract_chunks_chunk_index_idx ON public.contract_chunks(chunk_index);

-- Insert sample data only if the table is empty
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.contract_chunks LIMIT 1) THEN
    -- Insert sample chunks for general contracts
    INSERT INTO public.contract_chunks (doc_name, chunk_text, chunk_index, doc_type) VALUES
    ('general_terms_examples', 'This agreement establishes the terms between parties for service provision. Key elements include payment schedules, deliverables, and termination clauses. Red flags to watch: unlimited liability, vague scope definitions, and one-sided termination rights.', 1, 'general'),
    ('general_terms_examples', 'Payment terms should specify amounts, due dates, and late fees. Concerning clauses include: "payment at our sole discretion," automatic renewals without notice, and penalties exceeding actual damages.', 2, 'general'),
    ('general_terms_examples', 'Intellectual property clauses define ownership of work products. Warning signs: broad IP assignments, perpetual licenses, and claims to pre-existing IP. Fair terms clearly distinguish between work-for-hire and retained rights.', 3, 'general'),
    ('general_terms_examples', 'Termination provisions should be mutual and reasonable. Red flags include: termination without cause by one party only, excessive notice periods, and post-termination restrictions that are overly broad.', 4, 'general'),
    ('general_terms_examples', 'Dispute resolution clauses specify how conflicts are handled. Concerning terms: mandatory arbitration in distant locations, waiver of class action rights, and one-sided attorney fee provisions.', 5, 'general');

    -- Insert sample chunks for lease agreements
    INSERT INTO public.contract_chunks (doc_name, chunk_text, chunk_index, doc_type) VALUES
    ('lease_agreement_examples', 'Residential lease agreements define tenant and landlord obligations. Critical elements: rent amount, security deposits, maintenance responsibilities, and lease duration. Red flags: excessive fees, unclear maintenance duties, and restrictive guest policies.', 1, 'lease'),
    ('lease_agreement_examples', 'Security deposit terms should specify amount, conditions for return, and timeline. Warning signs: non-refundable deposits labeled as "fees," vague damage definitions, and automatic forfeiture clauses.', 2, 'lease'),
    ('lease_agreement_examples', 'Maintenance and repair clauses allocate responsibilities between parties. Concerning provisions: tenant responsible for all repairs, landlord entry without proper notice, and penalties for normal wear and tear.', 3, 'lease'),
    ('lease_agreement_examples', 'Early termination clauses should be fair and clearly defined. Red flags: excessive penalties, no early termination allowed, and forfeiture of entire security deposit for early departure.', 4, 'lease'),
    ('lease_agreement_examples', 'Pet and guest policies should be reasonable and clearly stated. Warning signs: blanket pet bans, excessive pet deposits, and unreasonable restrictions on overnight guests.', 5, 'lease');

    -- Insert sample chunks for employment contracts
    INSERT INTO public.contract_chunks (doc_name, chunk_text, chunk_index, doc_type) VALUES
    ('employment_contract_examples', 'Employment agreements define the relationship between employer and employee. Key components: job duties, compensation, benefits, and termination procedures. Red flags: vague job descriptions, below-market compensation, and excessive non-compete clauses.', 1, 'employment'),
    ('employment_contract_examples', 'Compensation and benefits should be clearly detailed. Warning signs: unpaid overtime expectations, benefit reductions without notice, and commission structures that favor the employer disproportionately.', 2, 'employment'),
    ('employment_contract_examples', 'Non-compete and confidentiality clauses should be reasonable in scope and duration. Concerning terms: overly broad non-competes, indefinite confidentiality periods, and restrictions on future employment opportunities.', 3, 'employment'),
    ('employment_contract_examples', 'Termination provisions should specify notice periods and severance. Red flags: at-will termination with no severance, immediate termination for minor infractions, and forfeiture of earned benefits upon termination.', 4, 'employment'),
    ('employment_contract_examples', 'Intellectual property clauses in employment should distinguish between work-related and personal creations. Warning signs: claims to all employee inventions, broad assignment of pre-existing IP, and restrictions on personal projects.', 5, 'employment');
  END IF;
END $$;

-- Create updated_at trigger for contract_chunks (only if the function exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_updated_at') THEN
    DROP TRIGGER IF EXISTS contract_chunks_updated_at ON public.contract_chunks;
    CREATE TRIGGER contract_chunks_updated_at
      BEFORE UPDATE ON public.contract_chunks
      FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
  END IF;
END $$;