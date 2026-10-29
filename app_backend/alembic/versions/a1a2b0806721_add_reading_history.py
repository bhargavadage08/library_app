"""add reading history

Revision ID: a1a2b0806721
Revises: 
Create Date: 2026-10-29 00:04:40.892224

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1a2b0806721'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        'reading_history',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('book_id', sa.Integer(), nullable=False),
        sa.Column('title', sa.String(), nullable=False),
        sa.Column('author', sa.String(), nullable=True),
        sa.Column('cover_url', sa.String(), nullable=True),
        sa.Column('current_page', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('total_pages', sa.Integer(), nullable=True),
        sa.Column('progress_percent', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('last_read_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'book_id', name='uq_user_book_history'),
    )
    op.create_index(op.f('ix_reading_history_book_id'), 'reading_history', ['book_id'], unique=False)
    op.create_index(op.f('ix_reading_history_id'), 'reading_history', ['id'], unique=False)
    op.create_index(op.f('ix_reading_history_user_id'), 'reading_history', ['user_id'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_reading_history_user_id'), table_name='reading_history')
    op.drop_index(op.f('ix_reading_history_id'), table_name='reading_history')
    op.drop_index(op.f('ix_reading_history_book_id'), table_name='reading_history')
    op.drop_table('reading_history')

