<?php

namespace ChurchCRM\Plugins\RgpdConformite;

use ChurchCRM\Plugin\AbstractPlugin;

class RgpdConformitePlugin extends AbstractPlugin
{
    public const DEFAULT_RETENTION_YEARS = 2;

    public function getId(): string
    {
        return 'rgpd-conformite';
    }

    public function getName(): string
    {
        return 'RGPD Compliance';
    }

    public function getDescription(): string
    {
        return 'GDPR / RGPD compliance toolkit for ChurchCRM.';
    }

    public function getVersion(): string
    {
        return '0.1.0';
    }

    public function boot(): void
    {
    }

    public function isConfigured(): bool
    {
        return $this->getDpoName() !== '' && $this->getDpoEmail() !== '';
    }

    public function isEnabled(): bool
    {
        return (bool) $this->getConfigValue('enabled');
    }

    public function getDpoName(): string
    {
        return trim((string) ($this->getConfigValue('dpoName') ?? ''));
    }

    public function getDpoEmail(): string
    {
        return trim((string) ($this->getConfigValue('dpoEmail') ?? ''));
    }

    public function getRetentionYears(): int
    {
        $raw = (string) ($this->getConfigValue('retentionYears') ?? '');
        if ($raw === '' || !ctype_digit($raw)) {
            return self::DEFAULT_RETENTION_YEARS;
        }

        return (int) $raw;
    }
}
